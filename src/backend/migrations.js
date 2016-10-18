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
            `CREATE TABLE chapters (id integer primary key,
                                    narration_id integer REFERENCES narrations(id),
                                    title string,
                                    audio string,
                                    background_image string,
                                    main_text text,
                                    created timestamp NOT NULL DEFAULT current_timestamp,
                                    updated timestamp NOT NULL DEFAULT current_timestamp,
                                    published timestamp)`
        ]);
    },

    function createReactionTable(db) {
        return statementListPromise(db, [
            `CREATE TABLE characters (id integer primary key,
                                      narration_id integer REFERENCES narrations(id),
                                      name string,
                                      token string)`,
            `CREATE TABLE reactions (id integer primary key,
                                     chapter_id integer references chapters(id) ON DELETE CASCADE,
                                     character_id integer references characters(id) ON DELETE CASCADE,
                                     main_text text)`
        ]);
    },

    function createUsersTable(db) {
        return statementListPromise(db, [
            `CREATE TABLE users (id integer primary key,
                                 username string unique,
                                 password string)`,
            `INSERT INTO users (username, password)
               VALUES ('narrator',
                       '$2a$04$NrMPbG7wG26EwqJOun.SLOELYGOmbFs5aECGxhl8suPfVY049NZdG')`
        ]);
    },

    function addUserRoles(db) {
        return statementListPromise(db, [
            `ALTER TABLE users ADD role string`,
            `ALTER TABLE characters ADD player_id integer REFERENCES users(id)`,
            `UPDATE users SET role = 'admin'`
        ]);
    },

    function createMessagesTables(db) {
        return statementListPromise(db, [
            `CREATE TABLE messages (id integer primary key,
                                    chapter_id integer REFERENCES chapters(id),
                                    sender_id integer REFERENCES characters(id),
                                    body text,
                                    sent timestamp NOT NULL DEFAULT current_timestamp)`,
            `CREATE TABLE message_deliveries (message_id integer REFERENCES messages(id),
                                              recipient_id integer REFERENCES characters(id))`
        ]);
    },

    function addNarrationNarrator(db) {
        return statementListPromise(db, [
            `ALTER TABLE narrations ADD narrator_id integer REFERENCES users(id)`
        ]);
    }
];

export default MIGRATIONS;
