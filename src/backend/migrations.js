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
            `CREATE TABLE narrations (id integer primary key,
                                      title string,
                                      default_audio string,
                                      default_background_image string)`,
            `CREATE TABLE fragments (id integer primary key,
                                     narration_id integer REFERENCES narrations(id),
                                     title string,
                                     audio string,
                                     background_image string,
                                     main_text text)`
        ]);
    },

    function createReactionTable(db) {
        return statementListPromise(db, [
            `CREATE TABLE characters (id integer primary key,
                                      narration_id integer REFERENCES narrations(id),
                                      name string,
                                      token string)`,
            `CREATE TABLE reactions (id integer primary key,
                                     fragment_id integer references fragments(id) ON DELETE CASCADE,
                                     character_id integer references characters(id) ON DELETE CASCADE,
                                     main_text text)`
        ]);
    }
];

export default MIGRATIONS;
