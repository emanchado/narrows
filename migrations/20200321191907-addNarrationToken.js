'use strict';

var dbm;
var type;
var seed;
var fs = require('fs');
var path = require('path');
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

function generateToken(a) {
    return a ?
        (a^Math.random()*16>>a/4).toString(16) :
        ([1e7]+-1e3+-4e3+-8e3+-1e11).replace(/[018]/g, generateToken);
}

exports.up = function(db) {
  var filePath = path.join(__dirname, 'sqls', '20200321191907-addNarrationToken-up.sql');
  return new Promise( function( resolve, reject ) {
    fs.readFile(filePath, {encoding: 'utf-8'}, function(err,data){
      if (err) return reject(err);

      resolve(data);
    });
  })
  .then(function(data) {
    return db.runSql(data);
  })
  .then(function(data) {
      return new Promise( function( resolve, reject ) {
          db.all("SELECT id FROM narrations", function(err, data){
              if (err) return reject(err);

              var narrationIds = data.map(function(row) { return row.id; });
              resolve(narrationIds);
          });
      });
  })
  .then(function(narrationIds) {
      var promise = new Promise(function(resolve, _) { resolve(true); });

      for (var i = 0; i < narrationIds.length; ++i) {
          var token = generateToken();
          promise = promise.then(db.runSql(
              "UPDATE narrations SET token = '" + token + "' WHERE id = " + narrationIds[i]
          ));
      }

      return promise;
  });
};

exports.down = function(db) {
  var filePath = path.join(__dirname, 'sqls', '20200321191907-addNarrationToken-down.sql');
  return new Promise( function( resolve, reject ) {
    fs.readFile(filePath, {encoding: 'utf-8'}, function(err,data){
      if (err) return reject(err);

      resolve(data);
    });
  })
  .then(function(data) {
    return db.runSql(data);
  });
};

exports._meta = {
  "version": 1
};
