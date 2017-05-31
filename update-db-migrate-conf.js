var fs = require("fs");
var config = require("config");

fs.writeFileSync("database.json", JSON.stringify({
    dev: {
        driver: "mysql",
        multipleStatements: true,
        host: config.db.host,
        user: config.db.user,
        password: config.db.password,
        database: config.db.database
    }
}));
