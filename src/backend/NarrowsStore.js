import fs from "fs-extra";
import path from "path";

import config from "config";
import mysql from "mysql";
import Q from "q";

import merge from "./merge";

const JSON_TO_DB = {
    id: "id",
    title: "title",
    audio: "audio",
    backgroundImage: "background_image",
    text: "main_text",
    published: "published",
    narratorId: "narrator_id",
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

function getFinalFilename(dir, filename) {
    const probePath = path.join(dir, filename);

    return Q.nfcall(fs.access, probePath).then(() => {
        const ext = path.extname(filename);
        const basename = path.basename(filename, ext);
        const newFilename = `${basename} extra${ext}`;

        return getFinalFilename(dir, newFilename);
    }).catch(() => probePath);
}

function pad(number) {
    return number < 10 ? `0${number}` : number;
}

function mysqlTimestamp(dateString) {
    if (!dateString) {
        return dateString;
    }

    const d = new Date(dateString);
    const year = d.getFullYear(),
          month = d.getMonth() + 1,
          day = d.getDate();
    const hour = d.getHours(),
          minutes = d.getMinutes(),
          seconds = d.getSeconds();

    return `${year}-${pad(month)}-${pad(day)} ` +
        `${pad(hour)}:${pad(minutes)}:${pad(seconds)}`;
}

class NarrowsStore {
    constructor(connConfig, narrationDir) {
        this.connConfig = connConfig;
        this.narrationDir = narrationDir;
    }

    connect() {
        this.db = new mysql.createConnection(this.connConfig);
        // Temporary extra methods for compatibility with the sqlite API
        this.db.run = function(stmt, binds, cb) {
            this.query(stmt, binds, function(err, results, fields) {
                cb(err, results);
            });
        };
        this.db.get = function(stmt, binds, cb) {
            this.query(stmt, binds, function(err, results, fields) {
                if (err) {
                    cb(err);
                    return;
                }
                if (results.length !== 1) {
                    cb('Did not receive exactly one result');
                    return;
                }
                cb(err, results[0]);
            });
        };
        this.db.all = function(stmt, binds, cb) {
            this.query(stmt, binds, function(err, results, fields) {
                cb(err, results);
            });
        };
    }

    createNarration(props) {
        const deferred = Q.defer();

        const fields = Object.keys(props).map(convertToDb);

        this.db.run(
            `INSERT INTO narrations (${ fields.join(", ") })
                VALUES (${ fields.map(() => "?").join(", ") })`,
            Object.keys(props).map(f => props[f]),
            function(err, result) {
                if (err) {
                    deferred.reject(err);
                    return;
                }

                const finalNarration = merge({ id: result.insertId },
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
            const chapterMap = {};
            chapters.forEach(chapter => {
                chapterMap[chapter.id] = chapter;
                chapter.reactions = [];
                chapter.numberMessages = 0;
            });

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
                  WHERE chapter_id IN (${ placeholders.join(", ") })`,
                chapters.map(f => f.id)
            ).then(reactions => {
                reactions.forEach(reaction => {
                    const chapter = chapterMap[reaction.chapterId];
                    chapter.reactions.push(reaction);
                });
                return [chapters, chapterMap];
            });
        }).spread((chapters, chapterMap) => {
            let placeholders = [];
            for (let i = 0; i < chapters.length; i++) {
                placeholders.push("?");
            }

            return Q.ninvoke(
                this.db,
                "all",
                `SELECT chapter_id AS chapterId, COUNT(*) AS numberMessages
                   FROM messages
                  WHERE chapter_id IN (${ placeholders.join(", ") })
               GROUP BY chapter_id`,
                chapters.map(f => f.id)
            ).then(numberMessagesPerChapter => {
                numberMessagesPerChapter.forEach(numberAndChapter => {
                    chapterMap[numberAndChapter.chapterId].numberMessages =
                        numberAndChapter.numberMessages;
                });

                return chapters;
            });
        });
    }

    _insertParticipants(id, participants) {
        let promise = Q(true);

        participants.forEach(participant => {
            promise = promise.then(() => {
                return Q.ninvoke(
                    this.db,
                    "run",
                    `INSERT INTO reactions (chapter_id, character_id)
                            VALUES (?, ?)`,
                    [id, participant.id]
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
              values = Object.keys(basicProps).map(f => (
                  f === "published" ?
                      mysqlTimestamp(basicProps[f]) : basicProps[f]
              ));

        const self = this;
        this.db.run(
            `INSERT INTO chapters
                (${ fieldString }, narration_id)
                VALUES (${ placeholderString }, ?)`,
            values.concat(narrationId),
            function(err, result) {
                if (err) {
                    deferred.reject(err);
                    return;
                }

                const newChapterId = result.insertId;

                self._insertParticipants(newChapterId, participants).then(() => {
                    return self.getChapter(newChapterId, { includePrivateFields: true });
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

    getCharacterEmails(characterIds) {
        const placeholders = characterIds.map(_ => "?");

        return Q.ninvoke(
            this.db,
            "all",
            `SELECT C.id, U.email
               FROM users U
               JOIN characters C
                 ON U.id = C.player_id
              WHERE C.id IN (${placeholders.join(', ')})`,
            characterIds
        ).then(rows => {
            const emails = {};
            rows.forEach(row => {
                emails[row.id] = row.email;
            });
            return emails;
        });
    }

    getChapterParticipants(chapterId, userOpts) {
        const opts = userOpts || {};
        const extraFields = opts.includePrivateFields ?
                  ", C.player_id, C.token, C.notes" : "";

        return Q.ninvoke(
            this.db,
            "all",
            `SELECT C.id, C.name, C.avatar, C.description ${ extraFields }
               FROM characters C JOIN reactions R ON C.id = R.character_id
              WHERE chapter_id = ?`,
            chapterId
        );
    }

    getChapter(id, opts) {
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

            chapterData.text = JSON.parse(chapterData.text.replace(/\r/g, ""));
            chapterData.text = fixBlockImages(chapterData.text);

            return this.getChapterParticipants(id, opts).then(participants => {
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

    getChapterReactions(id) {
        return Q.ninvoke(
            this.db,
            "all",
            `SELECT main_text AS text,
                    C.id AS characterId, C.name AS characterName
               FROM reactions R
               JOIN characters C
                 ON R.character_id = C.id
              WHERE chapter_id = ?`,
            id
        ).then(rows => (
            rows.map(row => ({
                character: { id: row.characterId, name: row.characterName },
                text: row.text
            }))
        ));
    }

    updateChapterParticipants(id, newParticipantList) {
        return this.getChapterParticipants(id).then(currentParticipantList => {
            const newHash = {}, currentHash = {};
            newParticipantList.forEach(newParticipant => {
                newHash[newParticipant.id] = true;
            });
            currentParticipantList.forEach(currentParticipant => {
                currentHash[currentParticipant.id] = true;
            });

            newParticipantList.forEach(newParticipant => {
                if (!currentHash.hasOwnProperty(newParticipant.id)) {
                    this.addParticipant(id, newParticipant.id);
                }
            });

            currentParticipantList.forEach(currentParticipant => {
                if (!newHash.hasOwnProperty(currentParticipant.id)) {
                    this.removeParticipant(id, currentParticipant.id);
                }
            });
        });
    }

    updateChapter(id, props) {
        const participants = props.participants;
        delete props.participants;

        const propNames = Object.keys(props).map(convertToDb),
              propNameStrings = propNames.map(p => `${p} = ?`);
        const propValues = Object.keys(props).map(n => (
            n === "published" ? mysqlTimestamp(props[n]) : props[n]
        ));

        return Q.ninvoke(
            this.db,
            "run",
            `UPDATE chapters SET ${ propNameStrings.join(", ") } WHERE id = ?`,
            propValues.concat(id)
        ).then(
            () => this.updateChapterParticipants(id, participants)
        ).then(
            () => this.getChapter(id, { includePrivateFields: true })
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

    getCharacterInfo(characterToken) {
        return Q.ninvoke(
            this.db,
            "get",
            "SELECT id, name, token, notes FROM characters WHERE token = ?",
            characterToken
        );
    }

    getCharacterTokenById(characterId) {
        return Q.ninvoke(
            this.db,
            "get",
            "SELECT token FROM characters WHERE id = ?",
            characterId
        ).then(
            row => row.token
        );
    }

    addCharacter(name, token, narrationId) {
        const deferred = Q.defer();

        this.db.run(
            `INSERT INTO characters (name, token, narration_id)
                             VALUES (?, ?, ?)`,
            [name, token, narrationId],
            function(err, result) {
                if (err) {
                    deferred.reject(err);
                    return;
                }

                deferred.resolve(result.insertId);
            }
        );

        return deferred.promise;
    }

    addParticipant(chapterId, characterId) {
        return this.getChapter(chapterId).then(() => (
            this.getChapterParticipants(chapterId,
                                        { includePrivateFields: true })
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
            this.getChapterParticipants(chapterId,
                                        { includePrivateFields: true })
        ));
    }

    /**
     * Adds a media file to the given narration, specifying its
     * filename and a temporary path where the file lives.
     */
    addMediaFile(narrationId, filename, tmpPath, type) {
        type = type ||
            (AUDIO_REGEXP.test(filename) ? "audio" : "backgroundImages");
        const filesDir = path.join(config.files.path, narrationId.toString());
        const typeDir = type === "backgroundImages" ?
                  "background-images" : type;
        const finalDir = path.join(filesDir, typeDir);

        return getFinalFilename(finalDir, filename).then(finalPath => {
            return Q.nfcall(fs.move, tmpPath, finalPath).then(() => ({
                name: path.basename(finalPath),
                type: type
            }));
        });
    }

    _formatMessageList(messages) {
        if (messages.length === 0) {
            return messages;
        }

        const messageIds = messages.map(m => m.id);
        const placeholders = messageIds.map(() => "?").join(", ");

        return Q.ninvoke(
            this.db,
            "all",
            `SELECT MD.message_id AS messageId,
                        MD.recipient_id AS recipientId,
                        C.name
                   FROM message_deliveries MD JOIN characters C
                     ON MD.recipient_id = C.id
                  WHERE message_id IN (${ placeholders })`,
            messageIds
        ).then(deliveries => {
            const deliveryMap = {};
            deliveries.forEach(({ messageId, recipientId, name }) => {
                deliveryMap[messageId] = deliveryMap[messageId] || [];
                deliveryMap[messageId].push({ id: recipientId,
                                              name: name });
            });

            messages.forEach(message => {
                message.recipients = deliveryMap[message.id];
            });

            return messages;
        }).then(messages => {
            const placeholders = messages.map(() => "?");

            return Q.ninvoke(
                this.db,
                "all",
                `SELECT id, name FROM characters
                      WHERE id IN (${ placeholders })`,
                messages.map(m => m.senderId)
            ).then(characters => {
                const characterMap = {};
                characters.forEach(c => {
                    characterMap[c.id] = {id: c.id, name: c.name};
                });

                messages.forEach(m => {
                    m.sender = characterMap[m.senderId];
                    delete m.senderId;
                });

                return messages;
            });
        });
    }

    getChapterMessages(chapterId, characterId) {
        return Q.ninvoke(
            this.db,
            "all",
            `SELECT DISTINCT id, sender_id AS senderId, body, sent AS sentAt
               FROM messages M LEFT JOIN message_deliveries MD
                 ON M.id = MD.message_id
              WHERE M.chapter_id = ?
                AND (recipient_id = ? OR sender_id = ?)
           ORDER BY sent`,
            [chapterId, characterId, characterId]
        ).then(
            this._formatMessageList.bind(this)
        );
    }

    getAllChapterMessages(chapterId) {
        return Q.ninvoke(
            this.db,
            "all",
            `SELECT DISTINCT id, sender_id AS senderId, body, sent AS sentAt
               FROM messages M LEFT JOIN message_deliveries MD
                 ON M.id = MD.message_id
              WHERE M.chapter_id = ?
           ORDER BY sent`,
            [chapterId]
        ).then(
            this._formatMessageList.bind(this)
        );
    }

    addMessage(chapterId, senderId, text, recipients) {
        const deferred = Q.defer();
        const self = this;

        this.db.run(
            `INSERT INTO messages (chapter_id, sender_id, body)
               VALUES (?, ?, ?)`,
            [chapterId, senderId, text],
            function(err, result) {
                if (err) {
                    deferred.reject(err);
                    return;
                }

                // Message without recipients is only for the narrator
                // (as the narrator is a "user", not a "character", it
                // cannot be in the recipient list, and instead is an
                // implicit recipient of all messages).
                if (!recipients.length) {
                    deferred.resolve({});
                    return;
                }

                const messageId = result.insertId;
                const valueQueryPart =
                          recipients.map(() => "(?, ?)").join(", ");
                const queryValues = recipients.reduce((acc, mr) => (
                    acc.concat(messageId, mr)
                ), []);

                Q.ninvoke(
                    self.db,
                    "run",
                    `INSERT INTO message_deliveries
                       (message_id, recipient_id) VALUES ${ valueQueryPart }`,
                    queryValues
                ).then(() => {
                    deferred.resolve({});
                }).catch(err => {
                    deferred.reject(err);
                });
            }
        );

        return deferred.promise;
    }

    getActiveChapter(characterId) {
        return Q.ninvoke(
            this.db,
            "get",
            `SELECT CHPT.id, CHPT.title, CHPT.published
               FROM chapters CHPT
               JOIN characters CHR
                 ON CHPT.narration_id = CHR.narration_id
               JOIN reactions REACT
                 ON (REACT.chapter_id = CHPT.id AND
                     REACT.character_id = CHR.id)
              WHERE CHR.id = ? AND published IS NOT NULL
           ORDER BY published DESC
              LIMIT 1`,
            characterId
        );
    }

    saveCharacterNotes(characterId, newNotes) {
        return Q.ninvoke(
            this.db,
            "run",
            `UPDATE characters SET notes = ? WHERE id = ?`,
            [newNotes, characterId]
        );
    }

    getChapterLastReactions(chapterId) {
        return Q.ninvoke(
            this.db,
            "get",
            `SELECT published, narration_id AS narrationId
               FROM chapters
              WHERE id = ?`,
            chapterId
        ).then(row => {
            const binds = [row.narrationId];
            let extraWhereClause = "";
            if (row.published) {
                extraWhereClause += "AND published < ?";
                binds.push(row.published);
            }
            binds.push(row.narrationId);

            return Q.ninvoke(
                this.db,
                "all",
            `SELECT CHPT.published AS chapterPublished,
                    CHPT.id AS chapterId, CHPT.title AS chapterTitle,
                    CHR.id AS characterId, CHR.name AS characterName,
                    R.main_text AS text
               FROM chapters CHPT
               JOIN characters CHR
                 ON CHPT.narration_id = CHR.narration_id
               JOIN reactions R
                 ON (R.chapter_id = CHPT.id AND R.character_id = CHR.id),
                     (SELECT MAX(CHAP.published) AS published, character_id
                        FROM reactions R
                        JOIN chapters CHAP
                          ON R.chapter_id = CHAP.id
                       WHERE narration_id = ?
                             ${ extraWhereClause }
                    GROUP BY character_id) AS reaction_per_character
              WHERE reaction_per_character.published = CHPT.published
                AND reaction_per_character.character_id = CHR.id
                AND CHR.narration_id = ?
                AND CHPT.published IS NOT NULL`,
                binds
            );
        });
    }

    getFullCharacterStats(characterId) {
        return Q.ninvoke(
            this.db,
            "get",
            `SELECT C.id, C.name, C.avatar, C.description, C.backstory,
                    N.id AS narrationId, N.title AS narrationTitle
               FROM characters C
               JOIN narrations N
                 ON C.narration_id = N.id
              WHERE C.id = ?`,
            characterId
        ).then(basicStats => {
            return Q.ninvoke(
                this.db,
                "all",
                `SELECT C.id, C.title
                   FROM chapters C
                   JOIN reactions R
                     ON C.id = R.chapter_id
                  WHERE narration_id = ?
                    AND published IS NOT NULL
                    AND R.character_id = ?`,
                [basicStats.narrationId, characterId]
            ).then(chapters => ({
                id: basicStats.id,
                name: basicStats.name,
                avatar: basicStats.avatar,
                description: JSON.parse(basicStats.description),
                backstory: JSON.parse(basicStats.backstory),
                narration: {
                    id: basicStats.narrationId,
                    title: basicStats.narrationTitle,
                    chapters: chapters
                }
            }));
        });
    }
}

export default NarrowsStore;
