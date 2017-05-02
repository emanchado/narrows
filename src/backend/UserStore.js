import mysql from "mysql";
import Q from "q";
import bcrypt from "bcrypt";

import merge from "./merge";

const PASSWORD_SALT_ROUNDS = 10;
const JSON_TO_DB = {
    id: "id",
    email: "email",
    password: "password",
    role: "role"
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
        this.db = new mysql.createConnection(this.connConfig);
    }

    authenticate(email, password) {
        return Q.ninvoke(
            this.db,
            "query",
            "SELECT id, password FROM users WHERE email = ?",
            email
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
            "SELECT id, email, role FROM users"
        ).spread(userRows => (
            userRows
        ));
    }

    getUser(userId) {
        return Q.ninvoke(
            this.db,
            "query",
            "SELECT id, email, role FROM users WHERE id = ?",
            userId
        ).spread(userRows => {
            if (userRows.length === 0) {
                throw new Error(`Cannot find user ${ userId }`);
            }

            return userRows[0];
        });
    }

    getUserByEmail(email) {
        return Q.ninvoke(
            this.db,
            "query",
            `SELECT id, email, role FROM users WHERE email = ?`,
            email
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

        this.db.query(
            `INSERT INTO users (${ fields.join(", ") })
                VALUES (${ fields.map(() => "?").join(", ") })`,
            Object.keys(props).map(f => props[f]),
            function(err, result) {
                if (err) {
                    deferred.reject(err);
                    return;
                }

                const finalUser = merge({ id: result.insertId }, props);
                deferred.resolve(finalUser);
            }
        );

        return deferred.promise;
    }

    isAdmin(userId) {
        return Q.ninvoke(
            this.db,
            "query",
            "SELECT role FROM users WHERE id = ?",
            userId
        ).spread(rows => (
            rows[0] && rows[0].role === "admin"
        ));
    }

    canActAs(userId, targetUserId) {
        if (userId === targetUserId) {
            return Q(true);
        }

        return Q.ninvoke(
            this.db,
            "query",
            "SELECT role FROM users WHERE id = ?",
            userId
        ).spread(rows => {
            if (!rows[0] || rows[0].role !== "admin") {
                throw new Error(
                    "User " + userId + " != " + targetUserId + " and " +
                        "not an admin"
                );
            }

            return userId;
        });
    }
}

export default UserStore;
