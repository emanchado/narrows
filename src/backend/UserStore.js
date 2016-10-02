import sqlite3 from "sqlite3";
import Q from "q";
import bcrypt from "bcrypt";

class UserStore {
    constructor(dbPath) {
        this.dbPath = dbPath;
    }

    connect() {
        this.db = new sqlite3.Database(this.dbPath);
    }

    authenticate(username, password) {
        return Q.ninvoke(
            this.db,
            "get",
            "SELECT password FROM users WHERE username = ?",
            username
        ).then(userRow => {
            if (!userRow) {
                return false;
            }

            const deferred = Q.defer();
            bcrypt.compare(password, userRow.password, function(err, res) {
                if (err) {
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
