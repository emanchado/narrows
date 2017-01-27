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

    authenticate(username, password) {
        return Q.ninvoke(
            this.db,
            "query",
            "SELECT password FROM users WHERE username = ?",
            username
        ).spread(userRows => {
            console.log("userRows =", userRows);
            if (userRows.length === 0) {
                return false;
            }

            const deferred = Q.defer();
            bcrypt.compare(password, userRows[0].password, function(err, res) {
                if (err) {
                    console.log("Failed with error:", err);
                    deferred.reject(err);
                    return;
                }
                deferred.resolve(res);
            });
            return deferred.promise;
        });
    }
}

export default UserStore;
