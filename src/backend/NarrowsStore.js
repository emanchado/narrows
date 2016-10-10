import fs from "fs";
import path from "path";

import config from "config";
import sqlite3 from "sqlite3";
import Q from "q";

import upgradeDb from "./sqlite-migrations";
import migrations from "./migrations";

const JSON_TO_DB = {
    id: "id",
    title: "title",
    audio: "audio",
    backgroundImage: "background_image",
    text: "main_text",
    published: "published"
};

const AUDIO_REGEXP = new RegExp("\.mp3$", "i");

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

    _getNarrationFiles(narrationId) {
        const filesDir = path.join(config.files.path, narrationId.toString());

        return Q.nfcall(fs.readdir, filesDir).then(files => {
            const types = {images: [], audio: []};

            files.forEach(file => {
                const type = AUDIO_REGEXP.test(file) ? "audio" : "images";
                types[type].push(file);
            });

            return types;
        });
    }

    getNarration(id) {
        return Q.ninvoke(
            this.db,
            "get",
            "SELECT * FROM narrations WHERE id = ?",
            id
        ).then(narrationInfo => {
            if (!narrationInfo) {
                throw new Error("Cannot find narration " + id);
            }

            return Q.all([
                Q.ninvoke(
                    this.db,
                    "all",
                    `SELECT id, name, token
                       FROM characters
                      WHERE narration_id = ?`,
                    id
                ),
                this._getNarrationFiles(id)
            ]).spread((characters, files) => {
                narrationInfo.characters = characters;
                narrationInfo.files = files;
                return narrationInfo;
            });
        });
    }

    getNarrationFragments(id) {
        return Q.ninvoke(
            this.db,
            "all",
            "SELECT id, title, published FROM fragments WHERE narration_id = ?",
            id
        ).then(fragments => {
            let placeholders = [];
            for (let i = 0; i < fragments.length; i++) {
                placeholders.push("?");
            }

            return Q.ninvoke(
                this.db,
                "all",
                `SELECT fragment_id AS fragmentId,
                        character_id AS characterId,
                        main_text AS text
                   FROM reactions
                  WHERE fragmentId IN (${ placeholders.join(", ") })`,
                fragments.map(f => f.id)
            ).then(reactions => {
                const fragmentMap = {};
                fragments.forEach(fragment => {
                    fragmentMap[fragment.id] = fragment;
                });
                reactions.forEach(reaction => {
                    const fragment = fragmentMap[reaction.fragmentId];
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

                self._insertParticipants(newFragmentId, fragmentProps.participants).then(() => {
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
                "main_text AS text, published FROM fragments WHERE id = ?",
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

    getFragmentReaction(id, characterId) {
        return Q.ninvoke(
            this.db,
            "get",
            `SELECT main_text AS text FROM reactions
              WHERE fragment_id = ? AND character_id = ?`,
            [id, characterId]
        ).then(
            row => row ? row.text : null
        );
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
        ).then(
            () => this.getFragment(id)
        );
    }

    updateReaction(fragmentId, characterId, reactionText) {
        return Q.ninvoke(
            this.db,
            "run",
            `UPDATE reactions SET main_text = ?
              WHERE fragment_id = ? AND character_id = ?`,
            [reactionText, fragmentId, characterId]
        );
    }

    getCharacterId(characterToken) {
        return Q.ninvoke(
            this.db,
            "get",
            "SELECT id FROM characters WHERE token = ?",
            characterToken
        ).then(
            characterRow => characterRow.id
        );
    }

    addParticipant(fragmentId, characterId) {
        return this.getFragment(fragmentId).then(() => (
            this.getFragmentParticipants(fragmentId)
        )).then(participants => {
            if (participants.some(p => p.id === characterId)) {
                return participants;
            }

            return Q.ninvoke(
                this.db,
                "run",
                `INSERT INTO reactions (fragment_id, character_id)
                    VALUES (?, ?)`,
                [fragmentId, characterId]
            );
        });
    }

    removeParticipant(fragmentId, characterId) {
        return Q.ninvoke(
            this.db,
            "run",
            `DELETE FROM reactions
                  WHERE fragment_id = ? AND character_id = ?`,
            [fragmentId, characterId]
        ).then(() => (
            this.getFragmentParticipants(fragmentId)
        ));
    }

    /**
     * Adds a media file to the given narration, specifying its
     * filename and a temporary path where the file lives.
     */
    addMediaFile(narrationId, filename, tmpPath) {
        const filesDir = path.join(config.files.path, narrationId.toString());
        const finalPath = path.join(filesDir, filename);

        return Q.nfcall(fs.rename, tmpPath, finalPath).then(() => {
            const type = AUDIO_REGEXP.test(filename) ? "audio" : "images";

            return { name: filename, type: type };
        });
    }
}

export default NarrowsStore;
