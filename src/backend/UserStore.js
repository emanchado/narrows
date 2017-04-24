import mysql from "mysql";
import Q from "q";
import bcrypt from "bcrypt";

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
                    console.error("Failed with error:", err);
                    deferred.reject(err);
                    return;
                }
                deferred.resolve(userRows[0].id);
            });
            return deferred.promise;
        });
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
