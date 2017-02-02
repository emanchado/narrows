import mysql from "mysql";
import DBMigrate from "db-migrate";
import Q from "q";

export function recreateDb(connConfig) {
    const conn = mysql.createConnection(Object.assign({},
                                                      connConfig,
                                                      {database: ''}));

    return Q.ninvoke(
        conn,
        "query",
        "DROP DATABASE IF EXISTS ??",
        [connConfig.database]
    ).then(() => (
        Q.ninvoke(
            conn,
            "query",
            "CREATE DATABASE ??",
            [connConfig.database]
        )
    )).then(() => {
        const migrationConfig = Object.assign({
            driver: "mysql",
            multipleStatements: true
        }, connConfig);
        const dbMigrate = DBMigrate.getInstance(true, {
            config: {
                dev: migrationConfig
            },
            cwd: "../"
        });
        dbMigrate.silence(true);
        return Q.ninvoke(dbMigrate, "up");
    });
}

export default recreateDb;
