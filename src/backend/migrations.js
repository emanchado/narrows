import Q from "q";

function statementListPromise(db, statements) {
    const promise = Q(true);

    db.serialize();
    statements.forEach(stmt => {
        promise.then(() => {
            Q.ninvoke(db, "exec", stmt);
        });
    });

    return promise;
}

const MIGRATIONS = [
    function createInitialTables(db) {
        return statementListPromise(db, [
            `CREATE TABLE _migrations (id integer primary key,
                                       name text)`,
            `CREATE TABLE fragments (id integer primary key,
                                     narration_id integer,
                                     title string,
                                     audio string,
                                     background_image string,
                                     main_text text)`
        ]);
    },

    function createReactionTable(db) {
        return statementListPromise(db, [
            `CREATE TABLE characters (id integer primary key,
                                      name string,
                                      token string)`,
            `CREATE TABLE reactions (id integer primary key,
                                     fragment_id integer,
                                     character_id integer,
                                     main_text text)`
        ]);
    }
];

export default MIGRATIONS;
