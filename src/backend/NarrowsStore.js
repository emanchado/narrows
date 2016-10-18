import fs from "fs-extra";
import path from "path";

import config from "config";
import sqlite3 from "sqlite3";
import Q from "q";

import upgradeDb from "./sqlite-migrations";
import migrations from "./migrations";
import merge from "./merge";

const JSON_TO_DB = {
    id: "id",
    title: "title",
    audio: "audio",
    backgroundImage: "background_image",
    text: "main_text",
    published: "published",
    defaultBackgroundImage: "default_background_image",
    defaultAudio: "default_audio"
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
    if (!jsonDoc || !jsonDoc.content) {
        return jsonDoc;
    }

    jsonDoc.content = jsonDoc.content.map(promoteBlockImages);
    return jsonDoc;
}

/**
 * Return a promise that returns the files in a directory. If the
 * directory doesn't exist, simply return an empty array.
 */
function filesInDir(dir) {
    return Q.nfcall(fs.readdir, dir).catch(() => []);
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

    createNarration(props) {
        const deferred = Q.defer();

        const fields = Object.keys(props).map(convertToDb);

        this.db.run(
            `INSERT INTO narrations (${ fields.join(", ") })
                VALUES (${ fields.map(() => "?").join(", ") })`,
            Object.keys(props).map(f => props[f]),
            function(err) {
                if (err) {
                    deferred.reject(err);
                    return;
                }

                const finalNarration = merge({ id: this.lastID },
                                             props);
                deferred.resolve(finalNarration);
            }
        );

        return deferred.promise;
    }

    _getNarrationFiles(narrationId) {
        const filesDir = path.join(config.files.path, narrationId.toString());

        return Q.all([
            filesInDir(path.join(filesDir, "background-images")),
            filesInDir(path.join(filesDir, "audio")),
            filesInDir(path.join(filesDir, "images"))
        ]).spread((backgroundImages, audio, images) => {
            return { backgroundImages, audio, images };
        });
    }

    getNarration(id) {
        return Q.ninvoke(
            this.db,
            "get",
            `SELECT id, title, default_audio AS defaultAudio,
                    default_background_image AS defaultBackgroundImage
               FROM narrations WHERE id = ?`,
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

    getNarrationChapters(id) {
        return Q.ninvoke(
            this.db,
            "all",
            "SELECT id, title, published FROM chapters WHERE narration_id = ?",
            id
        ).then(chapters => {
            let placeholders = [];
            for (let i = 0; i < chapters.length; i++) {
                placeholders.push("?");
            }

            return Q.ninvoke(
                this.db,
                "all",
                `SELECT chapter_id AS chapterId,
                        character_id AS characterId,
                        main_text AS text
                   FROM reactions
                  WHERE chapterId IN (${ placeholders.join(", ") })`,
                chapters.map(f => f.id)
            ).then(reactions => {
                const chapterMap = {};
                chapters.forEach(chapter => {
                    chapterMap[chapter.id] = chapter;
                });
                reactions.forEach(reaction => {
                    const chapter = chapterMap[reaction.chapterId];
                    chapter.reactions = chapter.reactions || [];
                    chapter.reactions.push(reaction);
                });
                return chapters;
            });
        });
    }

    _insertParticipants(id, participantIds) {
        let promise = Q(true);

        participantIds.forEach(pId => {
            promise = promise.then(() => {
                return Q.ninvoke(
                    this.db,
                    "run",
                    `INSERT INTO reactions (chapter_id, character_id)
                            VALUES (?, ?)`,
                    [id, pId]
                );
            });
        });

        return promise;
    }

    deleteChapter(id) {
        return Q.ninvoke(
            this.db,
            "run",
            "DELETE FROM chapters WHERE id = ?",
            id
        ).catch(err => true);
    }

    /**
     * Creates a new chapter for the given narration, with the given
     * properties. Properties have to include at least "text" (JSON in
     * ProseMirror format) and "participants" (an array of ids for the
     * characters in the chapter).
     */
    createChapter(narrationId, chapterProps) {
        if (!chapterProps.text) {
            throw new Error("Cannot create a new chapter without text");
        }

        if (!chapterProps.participants) {
            throw new Error("Cannot create a new chapter without participants");
        }

        return this.getNarration(narrationId).then(narration => {
            const basicProps = {
                backgroundImage: narration.defaultBackgroundImage,
                audio: narration.defaultAudio
            };
            Object.keys(JSON_TO_DB).forEach(field => {
                if (field in chapterProps) {
                    basicProps[field] = chapterProps[field];
                }
            });
            basicProps.text = JSON.stringify(basicProps.text);

            return this._insertChapter(narrationId,
                                       basicProps,
                                       chapterProps.participants);
        });
    }

    _insertChapter(narrationId, basicProps, participants) {
        const deferred = Q.defer();
        const fields = Object.keys(basicProps).map(convertToDb),
              fieldString = fields.join(", "),
              placeholderString = fields.map(f => "?").join(", "),
              values = Object.keys(basicProps).map(f => basicProps[f]);

        const self = this;
        this.db.run(
            `INSERT INTO chapters
                (${ fieldString }, narration_id)
                VALUES (${ placeholderString }, ?)`,
            values.concat(narrationId),
            function(err) {
                if (err) {
                    deferred.reject(err);
                    return;
                }

                const newChapterId = this.lastID;

                self._insertParticipants(newChapterId, participants).then(() => {
                    return self.getChapter(newChapterId);
                }).then(chapter => {
                    deferred.resolve(chapter);
                }).catch(err => {
                    return self.deleteChapter(newChapterId).then(() => {
                        deferred.reject(err);
                    });
                });
            }
        );

        return deferred.promise;
    }

    getChapterParticipants(chapterId) {
        return Q.ninvoke(
            this.db,
            "all",
            `SELECT C.id, C.name, C.token
               FROM characters C JOIN reactions R ON C.id = R.character_id
              WHERE chapter_id = ?`,
            chapterId
        );
    }

    getChapter(id) {
        return Q.ninvoke(
            this.db,
            "get",
            "SELECT id, title, audio, narration_id as narrationId, " +
                "background_image AS backgroundImage, " +
                "main_text AS text, published FROM chapters WHERE id = ?",
            id
        ).then(chapterData => {
            if (!chapterData) {
                throw new Error("Cannot find chapter " + id);
            }

            chapterData.text = JSON.parse(chapterData.text);
            chapterData.text = fixBlockImages(chapterData.text);

            return this.getChapterParticipants(id).then(participants => {
                chapterData.participants = participants;
                return chapterData;
            });
        });
    }

    getChapterReaction(id, characterId) {
        return Q.ninvoke(
            this.db,
            "get",
            `SELECT main_text AS text FROM reactions
              WHERE chapter_id = ? AND character_id = ?`,
            [id, characterId]
        ).then(
            row => row ? row.text : null
        );
    }

    updateChapter(id, props) {
        const propNames = Object.keys(props).map(convertToDb),
              propNameString = propNames.map(p => `${p} = ?`).join(", ");
        const propValues = Object.keys(props).map(n => props[n]);

        return Q.ninvoke(
            this.db,
            "run",
            `UPDATE chapters SET ${ propNameString } WHERE id = ?`,
            propValues.concat(id)
        ).then(
            () => this.getChapter(id)
        );
    }

    updateReaction(chapterId, characterId, reactionText) {
        return Q.ninvoke(
            this.db,
            "run",
            `UPDATE reactions SET main_text = ?
              WHERE chapter_id = ? AND character_id = ?`,
            [reactionText, chapterId, characterId]
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

    addParticipant(chapterId, characterId) {
        return this.getChapter(chapterId).then(() => (
            this.getChapterParticipants(chapterId)
        )).then(participants => {
            if (participants.some(p => p.id === characterId)) {
                return participants;
            }

            return Q.ninvoke(
                this.db,
                "run",
                `INSERT INTO reactions (chapter_id, character_id)
                    VALUES (?, ?)`,
                [chapterId, characterId]
            );
        });
    }

    removeParticipant(chapterId, characterId) {
        return Q.ninvoke(
            this.db,
            "run",
            `DELETE FROM reactions
                  WHERE chapter_id = ? AND character_id = ?`,
            [chapterId, characterId]
        ).then(() => (
            this.getChapterParticipants(chapterId)
        ));
    }

    /**
     * Adds a media file to the given narration, specifying its
     * filename and a temporary path where the file lives.
     */
    addMediaFile(narrationId, filename, tmpPath) {
        const filesDir = path.join(config.files.path, narrationId.toString());
        const type = AUDIO_REGEXP.test(filename) ? "audio" : "backgroundImages";
        const typeDir = type === "audio" ? "audio" : "background-images";
        const finalPath = path.join(filesDir, typeDir, filename);

        return Q.nfcall(fs.move, tmpPath, finalPath).then(() => {

            return { name: filename, type: type };
        });
    }
}

export default NarrowsStore;
