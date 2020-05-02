import path from "path";
import config from "config";
import Q from "q";

import UserStore from "./UserStore";

const STATIC_HTML_FILES = path.join(__dirname, "..", "html");

const userStore = new UserStore(config.db);
userStore.connect();

// Generic handler needed for the first-time setup
export function firstTimeSetup(req, res, next) {
    userStore.hasAnyAdmins().then(hasAdmin => {
        if (hasAdmin) {
            next();
        } else {
            if (req.body && req.body.email && req.body.password) {
                userStore.createUser({
                    email: req.body.email,
                    password: req.body.password,
                    role: "admin"
                }).then(newUser => {
                    req.session.userId = newUser.id;

                    next();
                });

                return;
            }

            res.sendFile(path.resolve(path.join(STATIC_HTML_FILES,
                                                "first-time-setup.html")));
        }
    }).catch(err => {
        res.statusCode = 401;
        res.send("Could not check if there are any admins in the app: " + err);
    });
}

export function getPasswordReset(req, res, next) {
    const token = req.params.token;

    userStore.getPasswordResetUserId(token).then(userId => {
        // If the password reset token is valid, create a valid
        // session for the user and redirect to the profile screen
        req.session.userId = userId;
        res.redirect("/profile");
    }).catch(err => {
        next();
    });
}

export function apiAuth(req, res, next) {
    if (req.session.userId) {
        next();
    } else {
        res.statusCode = 401;
        res.json({errorMessage: "Need to authenticate to use this API endpoint"});
    }
}
