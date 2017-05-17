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
    });
}

export function apiAuth(req, res, next) {
    if (req.session.userId) {
        next();
    } else {
        res.statusCode = 401;
        res.send("Need to authenticate to use this API endpoint");
    }
}

export function apiAdminAuth(req, res, next) {
    const userId = req.session.userId;

    if (userId) {
        userStore.isAdmin(userId).then(isAdmin => {
            if (isAdmin) {
                next();
            } else {
                res.statusCode = 403;
                res.send("Need to be an admin to use this API endpoint");
            }
        });
    } else {
        res.statusCode = 401;
        res.send("Need to authenticate to use this API endpoint");
    }
}
