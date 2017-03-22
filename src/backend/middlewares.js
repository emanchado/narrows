import path from "path";
import config from "config";
import Q from "q";

import UserStore from "./UserStore";

const STATIC_HTML_FILES = path.join(__dirname, "..", "html");

const userStore = new UserStore(config.db);
userStore.connect();

export function auth(req, res, next) {
    let promise = Q(true);

    if (req.body && req.body.username) {
        const { username, password } = req.body;
        promise = userStore.authenticate(username, password).then(userId => {
            req.session.userId = userId;
        });
    }

    return promise.then(() => {
        if (req.session.userId) {
            next();
        } else {
            res.statusCode = 401;
            res.sendFile(path.resolve(path.join(STATIC_HTML_FILES, "login.html")));
        }
    }).catch(err => {
        res.statusCode = 500;
        res.sendFile(path.resolve(path.join(STATIC_HTML_FILES, "login.html")));
    });
}

export function apiAuth(req, res, next) {
    if (req.session.userId) {
        next();
    } else {
        res.statusCode = 403;
        res.send("Need to authenticate to use this API endpoint");
    }
}
