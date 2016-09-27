import sqlite3 from "sqlite3";
import Q from "q";

import upgradeDb from "./sqlite-migrations";
import migrations from "./migrations";

const JSON_TO_DB = {
    id: "id",
    title: "title",
    audio: "audio",
    backgroundImage: "background_image",
    text: "main_text"
};

function convertToDb(fieldName) {
    if (!(fieldName in JSON_TO_DB)) {
        throw new Error("Don't understand field " + fieldName);
    }

    return JSON_TO_DB[fieldName];
}

function promoteBlockImages(block) {
    if (block.type === "paragraph" &&
        block.content && block.content.length === 1 &&
        block.content[0].type === "image") {
        return block.content[0];
    }

    return block;
}

function fixBlockImages(jsonDoc) {
    if (!jsonDoc) {
        return jsonDoc;
    }

    jsonDoc.content = jsonDoc.content.map(promoteBlockImages);
    return jsonDoc;
}

class NarrowsStore {
    constructor(dbPath, narrationDir) {
        this.dbPath = dbPath;
        this.narrationDir = narrationDir;
    }

    connect() {
        this.db = new sqlite3.Database(this.dbPath);
        return upgradeDb(this.db, migrations);
    }

    // TODO: This is just a placeholder, always returns ALL fragments
    getNarration(id) {
        return Q.ninvoke(
            this.db,
            "all",
            "SELECT id, title FROM fragments ORDER BY id"
        ).then(fragmentRows => {
            return {
                id: id,
                fragments: fragmentRows
            };
        });
    }

    createFragment(narrationId, fragmentProps) {
        const deferred = Q.defer();

        const fields = Object.keys(fragmentProps).map(convertToDb),
              fieldString = fields.join(", "),
              placeholderString = fields.map(f => "?").join(", "),
              values = Object.keys(fragmentProps).map(f => fragmentProps[f]);

        if (!fragmentProps.text) {
            throw new Error("Cannot create a new fragment without text");
        }

        const self = this;
        this.db.run(
            `INSERT INTO fragments
                (${ fieldString }, narration_id)
                VALUES (${ placeholderString }, ?)`,
            values.concat(narrationId),
            function(err) {
                if (err) {
                    deferred.reject(err);
                    return;
                }

                self.getFragment(this.lastID).then(fragment => {
                    deferred.resolve(fragment);
                });
            }
        );

        return deferred.promise;
    }

    getFragmentParticipants(fragmentId) {
        // TODO: This ALWAYS returns ALL characters, need to fix it to
        // return the participants in this fragment! Most likely needs
        // a "participants" table.
        return Q.ninvoke(
            this.db,
            "all",
            "SELECT id, name, token FROM characters"
        );
    }

    getFragment(id) {
        return Q.ninvoke(
            this.db,
            "get",
            "SELECT id, title, audio, narration_id as narrationId, " +
                "background_image AS backgroundImage, " +
                "main_text AS text FROM fragments WHERE id = ?",
            id
        ).then(fragmentData => {
            if (!fragmentData) {
                throw new Error("Cannot find fragment " + id);
            }

            fragmentData.text = JSON.parse(fragmentData.text);
            fragmentData.text = fixBlockImages(fragmentData.text);

            return this.getFragmentParticipants(id).then(participants => {
                fragmentData.participants = participants;
                return fragmentData;
            });
        });
    }

    updateFragment(id, props) {
        const propNames = Object.keys(props).map(convertToDb),
              propNameString = propNames.map(p => `${p} = ?`).join(", ");
        const propValues = Object.keys(props).map(n => props[n]);

        return Q.ninvoke(
            this.db,
            "run",
            `UPDATE fragments SET ${ propNameString } WHERE id = ?`,
            propValues.concat(id)
        ).then(() => {
            return this.getFragment(id);
        });
    }

    getReactions(fragmentId) {
        return Q.ninvoke(this.db, "all", "SELECT * FROM reactions");
    }

    saveReaction(fragmentId, characterId, reactionText) {
        return Q.ninvoke(
            this.db,
            "run",
            `INSERT INTO reactions (fragment_id, character_id, main_text)
                VALUES (?, ?, ?)`,
            [fragmentId, characterId, reactionText]
        );
    }

    getCharacterId(characterToken) {
        // TODO: Look up the real character id
        return Q(1);
    }
}

export default NarrowsStore;
