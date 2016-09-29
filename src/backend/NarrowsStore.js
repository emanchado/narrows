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

    getNarration(id) {
        return Q.ninvoke(
            this.db,
            "get",
            "SELECT * FROM narrations"
        );
    }

    getNarrationFragments(id) {
        return Q.ninvoke(
            this.db,
            "all",
            "SELECT id, title FROM fragments WHERE narration_id = ?",
            id
        ).then(fragments => {
            let placeholders = [];
            for (let i = 0; i < fragments.length; i++) {
                placeholders.push("?");
            }

            return Q.ninvoke(
                this.db,
                "all",
                `SELECT fragment_id, character_id, main_text FROM reactions
                  WHERE fragment_id IN (${ placeholders.join(", ") })`,
                fragments.map(f => f.id)
            ).then(reactions => {
                const fragmentMap = {};
                fragments.forEach(fragment => {
                    fragmentMap[fragment.id] = fragment;
                });
                reactions.forEach(reaction => {
                    const fragment = fragmentMap[reaction.fragment_id];
                    fragment.reactions = fragment.reactions || [];
                    fragment.reactions.push(reaction);
                });
                return fragments;
            });
        });
    }

    _insertParticipants(id, participantIds) {
        const promise = Q(true);

        participantIds.forEach(pId => {
            promise.then(() => {
                return Q.ninvoke(
                    this.db,
                    "run",
                    `INSERT INTO reactions (fragment_id, character_id)
                            VALUES (?, ?)`,
                    [id, pId]
                );
            });
        });

        return promise;
    }

    deleteFragment(id) {
        return Q.ninvoke(
            this.db,
            "run",
            "DELETE FROM fragments WHERE id = ?",
            id
        );
    }

    /**
     * Creates a new fragment for the given narration, with the given
     * properties. Properties have to include at least "text" (JSON in
     * ProseMirror format) and "participants" (an array of ids for the
     * characters in the fragment).
     */
    createFragment(narrationId, fragmentProps) {
        if (!fragmentProps.text) {
            throw new Error("Cannot create a new fragment without text");
        }

        if (!fragmentProps.participants) {
            throw new Error("Cannot create a new fragment without participants");
        }

        const basicProps = {};
        Object.keys(JSON_TO_DB).forEach(field => {
            if (field in fragmentProps) {
                basicProps[field] = fragmentProps[field];
            }
        });

        const deferred = Q.defer();
        const fields = Object.keys(basicProps).map(convertToDb),
              fieldString = fields.join(", "),
              placeholderString = fields.map(f => "?").join(", "),
              values = Object.keys(basicProps).map(f => basicProps[f]);

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

                const newFragmentId = this.lastID;

                this._insertParticipants(newFragmentId, fragmentProps.participants).then(() => {
                    return self.getFragment(newFragmentId);
                }).then(fragment => {
                    deferred.resolve(fragment);
                }).catch(err => {
                    return this.deleteFragment(newFragmentId).then(() => {
                        deferred.reject(err);
                    });
                });
            }
        );

        return deferred.promise;
    }

    getFragmentParticipants(fragmentId) {
        return Q.ninvoke(
            this.db,
            "all",
            `SELECT C.id, C.name, C.token
               FROM characters C JOIN reactions R ON C.id = R.character_id
              WHERE fragment_id = ?`,
            fragmentId
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
        return Q.ninvoke(
            this.db,
            "get",
            "SELECT id FROM characters WHERE token = ?",
            characterToken
        ).then(characterRow => characterRow.id);
    }
}

export default NarrowsStore;
