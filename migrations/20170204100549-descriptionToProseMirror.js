'use strict';

var util = require("util");

var dbm;
var type;
var seed;
var Promise;

/**
  * We receive the dbmigrate dependency from dbmigrate initially.
  * This enables us to not have to rely on NODE_PATH.
  */
exports.setup = function(options, seedLink) {
  dbm = options.dbmigrate;
  type = dbm.dataType;
  seed = seedLink;
  Promise = options.Promise;
};

exports.up = function(db) {
    return new Promise(function(resolve, reject) {
        db.all("SELECT id, description FROM characters", function(err, chars) {
            if (err) {
                reject(err);
            }

            Promise.all(chars.map(function(char) {
                var newDescription = JSON.stringify({
                    type: "doc",
                    content: [
                        {type: "paragraph",
                         content: [
                             {type: "text",
                              text: char.description || "No description."}
                         ]}
                    ]
                });

                return db.runSql(util.format(
                    "UPDATE characters SET description = %s WHERE id = %s",
                    db.escapeString(newDescription),
                    db.escapeString(String(char.id))
                ));
            })).then(
                resolve
            );
        });
    });
};

exports.down = function(db) {
    return new Promise(function(resolve, reject) {
        db.all("SELECT id, description FROM characters", function(err, chars) {
            if (err) {
                reject(err);
            }

            Promise.all(chars.map(function(char) {
                var newDescription =
                    JSON.parse(char.description).content[0].content[0].text || "";

                return db.runSql(util.format(
                    "UPDATE characters SET description = %s WHERE id = %s",
                    db.escapeString(newDescription),
                    db.escapeString(String(char.id))
                ));
            })).then(
                resolve
            );
        });
    });
};

exports._meta = {
  "version": 1
};
