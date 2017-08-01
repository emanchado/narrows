import fs from "fs-extra";
import path from "path";

import config from "config";
import mysql from "mysql";
import Q from "q";

import generateToken from "./token-generator";

const JSON_TO_DB = {
    id: "id",
    title: "title",
    status: "status",
    audio: "audio",
    backgroundImage: "background_image",
    text: "main_text",
    published: "published",
    narratorId: "narrator_id",
    defaultBackgroundImage: "default_background_image",
    defaultAudio: "default_audio",
    name: "name",
    description: "description",
    backstory: "backstory"
};

const AUDIO_REGEXP = new RegExp("\.mp3$", "i");

const VALID_NARRATION_STATUSES = ['active', 'finished', 'abandoned'];

function convertToDb(fieldName) {
    if (!(fieldName in JSON_TO_DB)) {
        throw new Error("Don't understand field " + fieldName);
    }

    return JSON_TO_DB[fieldName];
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
        this.db = new mysql.createPool(this.connConfig);
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

                const finalNarration = Object.assign({ id: result.insertId },
                                                     props);
                deferred.resolve(finalNarration);
            }
        );

        return deferred.promise;
    }

    updateNarration(narrationId, newProps) {
        if ("status" in newProps &&
                VALID_NARRATION_STATUSES.indexOf(newProps.status) === -1) {
            return Q.reject(new Error("Invalid status '" + newProps.status + "'"));
        }

        const propNames = Object.keys(newProps).map(convertToDb),
              propNameStrings = propNames.map(p => `${p} = ?`);
        const propValues = Object.keys(newProps).map(p => newProps[p]);

        if (!propValues.length) {
            return this.getNarration(narrationId);
        }

        return Q.ninvoke(
            this.db,
            "run",
            `UPDATE narrations SET ${ propNameStrings.join(", ") } WHERE id = ?`,
            propValues.concat(narrationId)
        ).then(
            () => this.getNarration(narrationId)
        );
    }

    _getNarrationCharacters(narrationId) {
        return Q.ninvoke(
            this.db,
            "all",
            `SELECT id, name, token
                       FROM characters
                      WHERE narration_id = ?`,
            narrationId
        );
    }

    _getPublicNarrationCharacters(narrationId) {
        return Q.ninvoke(
            this.db,
            "all",
            `SELECT id, name, avatar, description
               FROM characters
              WHERE narration_id = ?`,
            narrationId
        ).then(characters => {
            characters.forEach(c => {
                c.description = JSON.parse(c.description);
            });

            return characters;
        });
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
            `SELECT id, title, status, narrator_id AS narratorId,
                    default_audio AS defaultAudio,
                    default_background_image AS defaultBackgroundImage
               FROM narrations WHERE id = ?`,
            id
        ).then(narrationInfo => {
            if (!narrationInfo) {
                throw new Error("Cannot find narration " + id);
            }

            return Q.all([
                this._getNarrationCharacters(id),
                this._getNarrationFiles(id)
            ]).spread((characters, files) => {
                narrationInfo.characters = characters;
                narrationInfo.files = files;
                return narrationInfo;
            });
        });
    }

    getPublicNarration(id) {
        return Q.all([
            Q.ninvoke(
                this.db,
                "get",
                `SELECT id, title, default_audio AS defaultAudio,
                    default_background_image AS defaultBackgroundImage
               FROM narrations WHERE id = ?`,
                id
            ),
            this._getPublicNarrationCharacters(id)
        ]).spread((narrationInfo, characters) => {
            if (!narrationInfo) {
                throw new Error("Cannot find narration " + id);
            }

            narrationInfo.characters = characters;
            return narrationInfo;
        });
    }

    getNarrationChapters(id, userOpts) {
        const opts = Object.assign({ limit: -1 }, userOpts);
        const limitClause = opts.limit > 0 ?
              `LIMIT ${parseInt(opts.limit, 10)}` : "";

        return Q.ninvoke(
            this.db,
            "all",
            `SELECT id, title, published
               FROM chapters
              WHERE narration_id = ?
           ORDER BY COALESCE(published, created) DESC
                    ${ limitClause }`,
            id
        ).then(chapters => {
            if (chapters.length === 0) {
                return [[], {}];
            }

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
                `SELECT R.chapter_id AS chapterId,
                        R.character_id AS characterId,
                        C.name AS characterName,
                        R.main_text AS text
                   FROM reactions R
                   JOIN characters C ON R.character_id = C.id
                  WHERE chapter_id IN (${ placeholders.join(", ") })`,
                chapters.map(f => f.id)
            ).then(reactions => {
                reactions.forEach(reaction => {
                    const chapter = chapterMap[reaction.chapterId];
                    chapter.reactions.push({
                        character: { id: reaction.characterId,
                                     name: reaction.characterName },
                        text: reaction.text
                    });
                });
                return [chapters, chapterMap];
            });
        }).spread((chapters, chapterMap) => {
            if (chapters.length === 0) {
                return [];
            }

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

    getNarrationOverview(userId, opts) {
        const userOpts = Object.assign({ status: null }, opts);
        let extraConditions = "";
        const binds = [userId];

        if (userOpts.status) {
            extraConditions = " AND status = ?";
            binds.push(userOpts.status);
        }

        return Q.ninvoke(
            this.db,
            "all",
            `SELECT id, title, status, default_audio AS defaultAudio,
                    default_background_image AS defaultBackgroundImage
               FROM narrations
              WHERE narrator_id = ?
                    ${ extraConditions }
           ORDER BY created DESC`,
            binds
        ).then(rows => (
            Q.all([
                Q.all(rows.map(row => (
                    this.getNarrationChapters(row.id, { limit: 5 })
                ))),
                Q.all(rows.map(row => this._getNarrationCharacters(row.id))),
                Q.all(rows.map(row => this._getNarrationFiles(row.id)))
            ]).spread((chapterLists, characterLists, fileLists) => ({
                narrations: chapterLists.map((chapters, i) => ({
                    narration: Object.assign(rows[i],
                                             {characters: characterLists[i],
                                              files: fileLists[i]}),
                    chapters: chapters
                }))
            }))
        ));
    }

    deleteChapter(id) {
        return Q.ninvoke(
            this.db,
            "run",
            "DELETE FROM chapters WHERE id = ?",
            id
        ).catch(err => true);
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

    getNarratorEmail(narrationId) {
        return Q.ninvoke(
            this.db,
            "get",
            `SELECT email
               FROM narrations N
               JOIN users U
                 ON N.narrator_id = U.id
              WHERE N.id = ?`,
            narrationId
        ).then(
            narrationRow => narrationRow.email
        );
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
        ).then(participants => (
            participants.map(participant => (
                Object.assign(
                    participant,
                    { description: JSON.parse(participant.description) }
                )
            ))
        ));
    }

    isCharacterParticipant(characterId, chapterId) {
        return Q.ninvoke(
            this.db,
            "query",
            `SELECT COUNT(*) AS cnt
               FROM reactions
              WHERE character_id = ? AND chapter_id = ?`,
            [characterId, chapterId]
        ).spread(rows => (
            rows[0].cnt > 0
        )).catch(err => (
            false
        ));
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

        let updatePromise;
        if (Object.keys(props).length === 0) {
            // No regular fields to update, avoid SQL error
            updatePromise = Q(true);
        } else {
            const propNames = Object.keys(props).map(convertToDb),
                  propNameStrings = propNames.map(p => `${p} = ?`);
            const propValues = Object.keys(props).map(n => (
                n === "published" ? mysqlTimestamp(props[n]) : props[n]
            ));

            updatePromise = Q.ninvoke(
                this.db,
                "run",
                `UPDATE chapters SET ${ propNameStrings.join(", ") }
                  WHERE id = ?`,
                propValues.concat(id)
            );
        }

        return updatePromise.then(
            () => this.updateChapterParticipants(id, participants)
        ).then(
            () => this.getChapter(id, { includePrivateFields: true })
        );
    }

    updateReaction(chapterId, characterId, reactionText) {
        return this.getActiveChapter(characterId).then(activeChapter => {
            if (chapterId !== activeChapter.id) {
                throw new Error("Cannot send action for old chapters");
            }

            return Q.ninvoke(
                this.db,
                "run",
                `UPDATE reactions SET main_text = ?
                  WHERE chapter_id = ? AND character_id = ?`,
                [reactionText, chapterId, characterId]
            );
        });
    }

    getCharacterInfo(characterToken, extraFields) {
        extraFields = extraFields || [];
        const extraFieldString = extraFields.length !== 0 ?
              `, ${ extraFields.join(", ") }` :
              "";

        return Q.ninvoke(
            this.db,
            "get",
            `SELECT id, name, token, notes${ extraFieldString }
               FROM characters WHERE token = ?`,
            characterToken
        );
    }

    getCharacterInfoBulk(characterIds) {
        if (!characterIds.length) {
            return Q({});
        }

        const placeholders = characterIds.map(_ => "?");

        return Q.ninvoke(
            this.db,
            "all",
            `SELECT C.id, C.name, U.email
               FROM users U
               JOIN characters C
                 ON U.id = C.player_id
              WHERE C.id IN (${placeholders.join(', ')})`,
            characterIds
        ).then(rows => {
            const info = {};
            rows.forEach(row => {
                info[row.id] = { name: row.name, email: row.email };
            });
            return info;
        });
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

    addCharacter(name, userId, narrationId) {
        const deferred = Q.defer();

        const newToken = generateToken();

        return Q.ninvoke(
            this.db,
            "run",
            `INSERT INTO characters (name, token, player_id, narration_id)
                             VALUES (?, ?, ?, ?)`,
            [name, newToken, userId, narrationId]
        ).then(() => (
            this.getCharacterInfo(newToken)
        ));
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
        ).then(row => (
            this.getNarrationLastReactions(row.narrationId, row.published)
        ));
    }

    getNarrationLastReactions(narrationId, beforeDate) {
        const binds = [narrationId];
        let extraWhereClause = "";
        if (beforeDate) {
            extraWhereClause += "AND published < ?";
            binds.push(beforeDate);
        }
        binds.push(narrationId);

        return Q.ninvoke(
            this.db,
            "all",
            `SELECT CHPT.published AS chapterPublished,
                    CHPT.id AS chapterId, CHPT.title AS chapterTitle,
                    CHPT.main_text AS chapterText,
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
        ).then(reactions => {
            reactions.forEach(reaction => {
                reaction.chapterText = JSON.parse(reaction.chapterText.replace(/\r/g, ""));
            });

            return reactions;
        });
    }

    getCharacterChaptersBasic(characterId) {
        return Q.ninvoke(
            this.db,
            "all",
            `SELECT C.id, C.title
                   FROM chapters C
                   JOIN reactions R
                     ON C.id = R.chapter_id
                  WHERE published IS NOT NULL
                    AND R.character_id = ?`,
            characterId
        );
    }

    getCharacterChapters(characterId) {
        return Q.ninvoke(
            this.db,
            "all",
            `SELECT C.id, C.title, C.main_text AS text,
                    C.audio, C.background_image AS backgroundImage
               FROM chapters C
               JOIN reactions R
                 ON C.id = R.chapter_id
              WHERE published IS NOT NULL
                AND R.character_id = ?`,
            characterId
        ).then(chapters => {
            chapters.forEach(c => {
                c.text = JSON.parse(c.text.replace(/\r/g, ""));
            });

            return chapters;
        });
    }

    getFullCharacterStats(characterId) {
        return Q.all([
            Q.ninvoke(
                this.db,
                "get",
                `SELECT C.id, C.name, C.avatar, C.description, C.backstory,
                        N.id AS narrationId, N.title AS narrationTitle
                   FROM characters C
                   JOIN narrations N
                     ON C.narration_id = N.id
                  WHERE C.id = ?`,
                characterId
            ),
            this.getCharacterChaptersBasic(characterId)
        ]).spread((basicStats, chapters) => ({
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
    }

    updateCharacter(characterId, props) {
        const propNames = Object.keys(props).map(convertToDb),
              propNameStrings = propNames.map(p => `${p} = ?`);
        const propValues = Object.keys(props).map(p => props[p]);

        if (!propValues.length) {
            return this.getFullCharacterStats(characterId);
        }

        return Q.ninvoke(
            this.db,
            "run",
            `UPDATE characters SET ${ propNameStrings.join(", ") } WHERE id = ?`,
            propValues.concat(characterId)
        ).then(
            () => this.getFullCharacterStats(characterId)
        );
    }

    updateCharacterAvatar(characterId, filename, tmpPath) {
        return Q.ninvoke(
            this.db,
            "query",
            `SELECT narration_id AS narrationId FROM characters WHERE id = ?`,
            characterId
        ).spread(results => {
            const narrationId = results[0].narrationId;
            const filesDir = path.join(config.files.path, narrationId.toString());
            const fileExtension = path.extname(filename);
            const finalBasename = `${ characterId }${ fileExtension }`;
            const finalPath = path.join(filesDir, "avatars", finalBasename);

            return Q.nfcall(fs.move, tmpPath, finalPath, {clobber: true}).then(() => {
                return Q.ninvoke(
                    this.db,
                    "query",
                    `UPDATE characters SET avatar = ? WHERE id = ?`,
                    [finalBasename, characterId]
                );
            }).then(() => (
                this.getFullCharacterStats(characterId)
            ));
        });
    }

    getNovelInfo(novelToken) {
        return Q.ninvoke(
            this.db,
            "query",
            `SELECT NE.id, NE.token, NE.created,
                    NE.character_id AS characterId,
                    C.narration_id AS narrationId
               FROM narration_exports NE
               JOIN characters C ON NE.character_id = C.id
              WHERE NE.token = ?`,
            novelToken
        ).spread(results => {
            if (results.length !== 1) {
                throw new Error(
                    `Could not find (a single) novel with token ${novelToken}`
                );
            }

            return results[0];
        });
    }

    getNovels(narrationId) {
        return Q.ninvoke(
            this.db,
            "query",
            `SELECT NE.id, NE.token, NE.created,
                    NE.character_id AS characterId
               FROM narration_exports NE
               JOIN characters C ON NE.character_id = C.id
              WHERE C.narration_id = ?`,
            narrationId
        ).spread(results => (
            results
        ));
    }

    createNovel(characterId) {
        const novelToken = generateToken();

        return Q.ninvoke(
            this.db,
            "query",
            `INSERT INTO narration_exports (character_id, token) VALUES (?, ?)`,
            [characterId, novelToken]
        ).then(() => (
            this.getNovelInfo(novelToken)
        ));
    }
}

export default NarrowsStore;
