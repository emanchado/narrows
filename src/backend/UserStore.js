import mysql from "mysql";
import Q from "q";
import bcrypt from "bcrypt";

import generateToken from "./token-generator";

const PASSWORD_SALT_ROUNDS = 10;
const PASSWORD_RESET_TOKEN_TTL = 60 * 60; // One hour
const UNVERIFIED_USER_TTL = 7 * 24 * 60 * 60; // One week
const JSON_TO_DB = {
    id: "id",
    email: "email",
    displayName: "display_name",
    password: "password",
    role: "role",
    verified: "verified",
    created: "created"
};

function convertToDb(fieldName) {
    if (!(fieldName in JSON_TO_DB)) {
        throw new Error("Don't understand field " + fieldName);
    }

    return JSON_TO_DB[fieldName];
}

class UserStore {
    constructor(connConfig) {
        this.connConfig = connConfig;
    }

    connect() {
        this.db = new mysql.createPool(this.connConfig);
    }

    authenticate(email, password) {
        return Q.ninvoke(
            this.db,
            "query",
            "SELECT id, password FROM users WHERE email = ?",
            email.trim()
        ).spread(userRows => {
            if (userRows.length === 0) {
                return false;
            }

            const deferred = Q.defer();
            bcrypt.compare(password, userRows[0].password, function(err, res) {
                if (err || !res) {
                    deferred.reject(err);
                    return;
                }
                deferred.resolve(userRows[0].id);
            });
            return deferred.promise;
        });
    }

    getUsers() {
        return Q.ninvoke(
            this.db,
            "query",
            `SELECT id, email, display_name AS displayName,
                    COALESCE(role, '') AS role, verified, created
               FROM users`
        ).spread(userRows => {
            // Force the "verified" field to be boolean. It comes as
            // an integer from MySQL, annoyingly.
            userRows.forEach(row => {
                row.verified = !!row.verified;
            });
            return userRows;
        });
    }

    getUser(userId) {
        return Q.ninvoke(
            this.db,
            "query",
            `SELECT id, email, display_name AS displayName,
                    COALESCE(role, '') AS role, verified, created
               FROM users
              WHERE id = ?`,
            userId
        ).spread(userRows => {
            if (userRows.length === 0) {
                throw new Error(`Cannot find user ${ userId }`);
            }

            userRows[0].verified = !!userRows[0].verified;
            return userRows[0];
        });
    }

    getUserByEmail(email) {
        return Q.ninvoke(
            this.db,
            "query",
            `SELECT id, email, COALESCE(role, '') AS role, verified
               FROM users
              WHERE email = ?`,
            email.trim()
        ).spread(userRows => {
            if (userRows.length === 0) {
                throw new Error(`Cannot find user with e-mail ${ email }`);
            }

            return userRows[0];
        });
    }

    updateUser(userId, props) {
        // Empty password means "no change"
        if (props.password === "") {
            delete props.password;
        }

        if (Object.keys(props).length === 0) {
            return this.getUser(userId);
        }

        if ("password" in props) {
            props.password = bcrypt.hashSync(props.password,
                                             PASSWORD_SALT_ROUNDS);
        }

        const propNames = Object.keys(props).map(convertToDb),
              propNameStrings = propNames.map(p => `${p} = ?`);
        const propValues = Object.keys(props).map(p => props[p]);

        return Q.ninvoke(
            this.db,
            "query",
            `UPDATE users SET ${ propNameStrings.join(", ") } WHERE id = ?`,
            propValues.concat(userId)
        ).then(
            () => this.getUser(userId)
        );
    }

    createEmailVerificationToken(userId) {
        const emailVerificationToken = generateToken();

        return Q.ninvoke(
            this.db,
            "query",
            `INSERT INTO user_tokens (user_id, token, token_type)
                              VALUES (?, ?, 'email_verification')`,
            [userId, emailVerificationToken]
        ).then(() => (
            emailVerificationToken
        ));
    }

    verifyEmail(token) {
        return Q.ninvoke(
            this.db,
            "query",
            `SELECT user_id AS userId
               FROM user_tokens
              WHERE token = ?
                AND token_type = 'email_verification'`,
            token
        ).spread(rows => (
            rows.length === 1 ?
                Q.all([
                    Q.ninvoke(
                        this.db,
                        "query",
                        `UPDATE users
                            SET verified = TRUE
                          WHERE id = ?`,
                        rows[0].userId
                    ),
                    Q.ninvoke(
                        this.db,
                        "query",
                        `DELETE FROM user_tokens
                          WHERE token = ?
                            AND token_type = 'email_verification'`,
                        token
                    )
                ]) :
                Q.reject("No such email verification token")
        ));
    }

    createUser(props) {
        const deferred = Q.defer();

        if (!props.email) {
            deferred.reject(
                new Error("Cannot create a user without e-mail address")
            );
            return deferred.promise;
        }

        if ("password" in props) {
            props.password = bcrypt.hashSync(props.password,
                                             PASSWORD_SALT_ROUNDS);
        }

        const fields = Object.keys(props).map(convertToDb);
        props.email = props.email.trim();

        return Q.ninvoke(
            this.db,
            "query",
            `INSERT INTO users (${ fields.join(", ") })
                VALUES (${ fields.map(() => "?").join(", ") })`,
            Object.keys(props).map(f => props[f])
        ).then(result => {
            const userId = result[0].insertId;

            let promise = Q(true);

            if (!("displayName" in props)) {
                props.displayName = `User #${userId}`;
                promise = promise.then(
                    Q.ninvoke(
                        this.db,
                        "query",
                        `UPDATE users SET display_name = ? WHERE id = ?`,
                        [props.displayName, userId]
                    )
                );
            }

            return promise.then(() => (
                this.getUser(userId)
            ));
        });
    }

    isAdmin(userId) {
        if (!userId) {
            throw new Error(`You need to pass a userId to the function`);
        }

        return Q.ninvoke(
            this.db,
            "query",
            "SELECT role FROM users WHERE id = ?",
            [userId]
        ).spread(rows => (
            rows[0] && rows[0].role === "admin"
        ));
    }

    canActAs(userId, targetUserId) {
        if (userId === targetUserId) {
            return Q(true);
        }

        return this.isAdmin(userId).then(isAdmin => {
            if (!isAdmin) {
                throw new Error(
                    "User " + userId + " != " + targetUserId + " and " +
                        "not an admin"
                );
            }

            return userId;
        });
    }

    hasAnyAdmins() {
        return Q.ninvoke(
            this.db,
            "query",
            "SELECT COUNT(*) AS adminCount FROM users WHERE role = 'admin'"
        ).spread(rows => {
            return rows[0].adminCount > 0;
        });
    }

    _deletePasswordResetToken(token) {
        return Q.ninvoke(
            this.db,
            "query",
            `DELETE FROM user_tokens
              WHERE token = ?
                AND token_type = 'password_reset'`,
            token
        );
    }

    _deleteOldPasswordResetTokens() {
        return Q.ninvoke(
            this.db,
            "query",
            `DELETE FROM user_tokens
              WHERE TIME_TO_SEC(TIMEDIFF(CURRENT_TIMESTAMP, created)) > ?
                AND token_type = 'password_reset'`,
            PASSWORD_RESET_TOKEN_TTL
        );
    }

    deleteOldUnverifiedUsers(unverified_user_ttl) {
        const ttl = unverified_user_ttl || UNVERIFIED_USER_TTL;

        return Q.ninvoke(
            this.db,
            "query",
            `DELETE FROM users
              WHERE verified = FALSE
                AND created < NOW() - INTERVAL ? SECOND`,
            [ttl]
        );
    }

    makePasswordResetLink(email) {
        return this._deleteOldPasswordResetTokens().then(() => (
            this.getUserByEmail(email)
        )).then(user => {
            const passwordResetCode = generateToken();

            return Q.ninvoke(
                this.db,
                "query",
                `INSERT INTO user_tokens (user_id, token, token_type)
                      VALUES (?, ?, 'password_reset')`,
                [user.id, passwordResetCode]
            ).then(() => (
                passwordResetCode
            ));
        });
    }

    getPasswordResetUserId(token) {
        return this._deleteOldPasswordResetTokens().then(() => (
            Q.ninvoke(
                this.db,
                "query",
                `SELECT user_id AS userId
                   FROM user_tokens
                  WHERE token = ?
                    AND token_type = 'password_reset'`,
                token
            )
        )).spread(rows => {
            if (rows.length) {
                return rows[0].userId;
            }

            throw new Error(`Cannot find password reset token ${ token }`);
        }).then(userId => {
            return this._deletePasswordResetToken(token).then(() => (
                userId
            ));
        });
    }

    deleteUser(userId) {
        return Q.ninvoke(
            this.db,
            "query",
            `DELETE FROM users
              WHERE id = ?`,
            userId
        );
    }
}

export default UserStore;
