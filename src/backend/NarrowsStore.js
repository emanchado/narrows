import fs from "fs-extra";
import path from "path";

import config from "config";
import mysql from "mysql";
import Q from "q";
import ejs from "ejs";

import generateToken from "./token-generator";

const JSON_TO_DB = {
    id: "id",
    title: "title",
    intro: "intro",
    status: "status",
    audio: "audio",
    backgroundImage: "background_image",
    text: "main_text",
    published: "published",
    narratorId: "narrator_id",
    introBackgroundImage: "intro_background_image",
    introAudio: "intro_audio",
    defaultBackgroundImage: "default_background_image",
    defaultAudio: "default_audio",
    notes: "notes",
    name: "name",
    description: "description",
    backstory: "backstory",
    introSent: "intro_sent",
    playerId: "player_id"
};

const AUDIO_REGEXP = new RegExp("\.mp3$", "i");

const VALID_NARRATION_STATUSES = ['active', 'finished', 'abandoned'];

const NARRATION_STYLES_CSS_TEMPLATE = `
<% if (titleFont) { %>
@font-face {
  font-family: "NARROWS heading user font";
  src: url("fonts/<%= titleFont %>");
}
<% } %>
<% if (bodyTextFont) { %>
@font-face {
  font-family: "NARROWS body user font";
  src: url("fonts/<%= bodyTextFont %>");
}
<% } %>
<% if (titleFont || titleColor || titleShadowColor) { %>
#top-image {
<% if (titleFont) { %>
    font-family: "NARROWS heading user font";
<% } %>
<% if (titleFontSize) { %>
    font-size: <%= titleFontSize %>px;
<% } %>
<% if (titleColor) { %>
    color: <%= titleColor %>;
<% } %>
<% if (titleShadowColor) { %>
    text-shadow: 3px 3px 0 <%= titleShadowColor %>, -1px -1px 0 <%= titleShadowColor %>, 1px -1px 0 <%= titleShadowColor %>, -1px 1px 0 <%= titleShadowColor %>, 1px 1px 0 <%= titleShadowColor %>;
<% } %>
}
<% } %>

<% if (bodyTextFont || bodyTextFontSize) { %>
.chapter {
<% if (bodyTextFont) { %>
    font-family: "NARROWS body user font";
<% } %>
<% if (bodyTextFontSize) { %>
    font-size: <%= bodyTextFontSize %>px;
<% } %>
}
<% } %>
<% if (bodyTextColor || bodyTextBackgroundColor) { %>
.chapter > p, .chapter > blockquote,
.chapter > h1, .chapter > h2, .chapter > h3,
.chapter ul, .chapter ol, .chapter .separator {
<% if (bodyTextColor) { %>
    color: <%= bodyTextColor %>;
<% } %>
<% if (bodyTextBackgroundColor) { %>
    background-color: <%= bodyTextBackgroundColor %>;
<% } %>
}
<% } %>
<% if (separatorImage) { %>
.chapter .separator {
    background-image: url(/static/narrations/<%= narrationId %>/images/<%= separatorImage %>);
}
<% } %>
`;

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

// Parses the JSON text for a narration intro and returns the parsed
// JS object. If the intro is effectively empty, return null as if the
// input had been null.
function parseIntroText(introText) {
    const parsedIntro = JSON.parse(introText);

    if (
        parsedIntro &&
            parsedIntro.content &&
            parsedIntro.content.length === 1 &&
            !("content" in parsedIntro.content[0])
    ) {
        return null;
    }
    return parsedIntro;
}

function escapeCss(cssText) {
    return (typeof cssText === 'string') ?
        cssText.replace(new RegExp('[/;]', 'ig'), '') :
        cssText;
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

        const fields = Object.keys(props).map(convertToDb).concat("token");
        const token = generateToken();

        this.db.run(
            `INSERT INTO narrations (${ fields.join(", ") })
                VALUES (${ fields.map(() => "?").join(", ") })`,
            Object.keys(props).map(f => props[f]).concat(token),
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

    _updateNarrationStyles(narrationId, newStyles) {
        const cssFilePath = path.join(config.files.path,
                                      narrationId.toString(),
                                      "styles.css");

        if (
            Object.keys(newStyles).every(name => (
                newStyles[name] === null || newStyles[name] === ''
            ))
        ) {
            return Q.ninvoke(
                this.db,
                "run",
                "DELETE FROM narration_styles WHERE narration_id = ?",
                narrationId
            ).then(() => {
                fs.removeSync(cssFilePath);
            });
        } else {
            return Q.ninvoke(
                this.db,
                "run",
                `REPLACE INTO narration_styles
                                  (narration_id, title_font, title_font_size,
                                   title_color, title_shadow_color,
                                   body_text_font, body_text_font_size,
                                   body_text_color, body_text_background_color,
                                   separator_image)
                           VALUES (?, ?, ?,
                                   ?, ?,
                                   ?, ?,
                                   ?, ?,
                                   ?)`,
                [narrationId, newStyles.titleFont, newStyles.titleFontSize,
                 newStyles.titleColor, newStyles.titleShadowColor,
                 newStyles.bodyTextFont, newStyles.bodyTextFontSize,
                 newStyles.bodyTextColor, newStyles.bodyTextBackgroundColor,
                 newStyles.separatorImage]
            ).then(() => {
                const cssText = ejs.render(
                    NARRATION_STYLES_CSS_TEMPLATE,
                    Object.assign({narrationId: narrationId}, newStyles),
                    {escape: escapeCss}
                );
                fs.writeFileSync(cssFilePath, cssText);
            });
        }
    }

    updateNarration(narrationId, newProps) {
        let initialPromise = Q(null);

        if ("status" in newProps &&
                VALID_NARRATION_STATUSES.indexOf(newProps.status) === -1) {
            return Q.reject(new Error("Invalid status '" + newProps.status + "'"));
        }
        if ("intro" in newProps) {
            newProps.intro = JSON.stringify(newProps.intro);
        }
        if ("styles" in newProps) {
            const newStyles = newProps.styles;
            delete newProps.styles;

            initialPromise = this._updateNarrationStyles(narrationId, newStyles);
        }

        const propNames = Object.keys(newProps).map(convertToDb),
              propNameStrings = propNames.map(p => `${p} = ?`);
        const propValues = Object.keys(newProps).map(p => newProps[p]);

        if (!propValues.length) {
            return this.getNarration(narrationId);
        }

        return initialPromise.then(() => (
            Q.ninvoke(
                this.db,
                "run",
                `UPDATE narrations SET ${ propNameStrings.join(", ") } WHERE id = ?`,
                propValues.concat(narrationId)
            ).then(
                () => this.getNarration(narrationId)
            )
        ));
    }

    _getNarrationCharacters(narrationId) {
        return Q.ninvoke(
            this.db,
            "all",
            `SELECT characters.id, name, display_name AS displayName,
                    token, novel_token AS novelToken, avatar
               FROM characters
          LEFT JOIN users
                 ON characters.player_id = users.id
              WHERE narration_id = ?`,
            narrationId
        );
    }

    _getPublicNarrationCharacters(narrationId) {
        return Q.ninvoke(
            this.db,
            "all",
            `SELECT id, player_id IS NOT NULL AS claimed, name, avatar, description
               FROM characters
              WHERE narration_id = ?`,
            narrationId
        ).then(characters => {
            characters.forEach(c => {
                c.claimed = !!c.claimed;
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
            filesInDir(path.join(filesDir, "images")),
            filesInDir(path.join(filesDir, "fonts"))
        ]).spread((backgroundImages, audio, images, fonts) => {
            return { backgroundImages, audio, images, fonts };
        });
    }

    getNarration(id) {
        return Q.ninvoke(
            this.db,
            "get",
            `SELECT id, token, title, intro, status,
                    narrator_id AS narratorId,
                    intro_background_image AS introBackgroundImage,
                    intro_audio AS introAudio,
                    default_audio AS defaultAudio,
                    default_background_image AS defaultBackgroundImage,
                    COALESCE(notes, '') AS notes
               FROM narrations WHERE id = ?`,
            id
        ).then(narrationInfo => {
            if (!narrationInfo) {
                throw new Error("Cannot find narration " + id);
            }
            if (narrationInfo.intro) {
                narrationInfo.intro = parseIntroText(narrationInfo.intro);
            }
            narrationInfo.introUrl = `${config.publicAddress}/narrations/${narrationInfo.token}/intro`;

            return Q.all([
                this._getNarrationCharacters(id),
                this._getNarrationFiles(id),
                this._getNarrationStyles(id)
            ]).spread((characters, files, styles) => {
                narrationInfo.characters = characters;
                narrationInfo.files = files;
                narrationInfo.styles = styles;
                return narrationInfo;
            });
        });
    }

    getNarratorId(narrationId) {
        return Q.ninvoke(
            this.db,
            "get",
            `SELECT narrator_id AS narratorId
               FROM narrations WHERE id = ?`,
            narrationId
        ).then(narrationInfo => {
            if (!narrationInfo) {
                throw new Error("Cannot find narration " + narrationId);
            }

            return narrationInfo.narratorId;
        });
    }

    getNarrationByToken(token) {
        return Q.ninvoke(
            this.db,
            "get",
            `SELECT id, title, intro, status, narrator_id AS narratorId,
                    intro_background_image AS backgroundImage,
                    intro_audio AS audio
               FROM narrations WHERE token = ?`,
            token
        ).then(narrationInfo => {
            if (!narrationInfo) {
                throw new Error("Cannot find narration " + token);
            }
            if (narrationInfo.intro) {
                narrationInfo.intro = parseIntroText(narrationInfo.intro);
            }

            return this._getPublicNarrationCharacters(narrationInfo.id).then(characters => {
                narrationInfo.characters = characters;
                return narrationInfo;
            });
        });
    }

    getPublicNarration(id) {
        return Q.all([
            Q.ninvoke(
                this.db,
                "get",
                `SELECT id, title, intro, intro_audio AS introAudio,
                    intro_background_image AS introBackgroundImage,
                    default_audio AS defaultAudio,
                    default_background_image AS defaultBackgroundImage
               FROM narrations WHERE id = ?`,
                id
            ),
            this._getPublicNarrationCharacters(id)
        ]).spread((narrationInfo, characters) => {
            if (!narrationInfo) {
                throw new Error("Cannot find narration " + id);
            }

            narrationInfo.intro = parseIntroText(narrationInfo.intro);
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
                chapter.participants = [];
                chapter.activeUsers = [];
                chapter.numberMessages = 0;
            });

            return [chapters, chapterMap];
        }).spread((chapters, chapterMap) => {
            if (chapters.length === 0) {
                return [];
            }

            const placeholders = chapters.map(_ => "?");

            return Q.ninvoke(
                this.db,
                "all",
                `SELECT chapter_id AS chapterId,
                        COUNT(*) AS numberMessages
                   FROM messages
                  WHERE chapter_id IN (${ placeholders.join(", ") })
               GROUP BY chapter_id`,
                chapters.map(f => f.id)
            ).then(numberMessagesPerChapter => {
                numberMessagesPerChapter.forEach(numberAndChapter => {
                    chapterMap[numberAndChapter.chapterId].numberMessages =
                        numberAndChapter.numberMessages;
                });

                return Q.ninvoke(
                    this.db,
                    "all",
                    `SELECT DISTINCT chapter_id AS chapterId,
                            CH.id, CH.name, CH.avatar
                       FROM messages M
                       JOIN characters CH
                         ON M.sender_id = CH.id
                      WHERE chapter_id IN (${ placeholders.join(", ") })`,
                    chapters.map(f => f.id)
                );
            }).then(activeUsers => {
                activeUsers.forEach(({ chapterId, name, avatar }) => {
                    chapterMap[chapterId].activeUsers.push({
                        id: id,
                        name: name,
                        avatar: avatar
                    });
                });

                return Q.ninvoke(
                    this.db,
                    "all",
                    `SELECT chapter_id AS chapterId,
                            CH.id, CH.name, CH.avatar
                       FROM chapter_participants CP
                       JOIN characters CH
                         ON CP.character_id = CH.id
                      WHERE chapter_id IN (${ placeholders.join(", ") })`,
                    chapters.map(f => f.id)
                );
            }).then(participants => {
                participants.forEach(({ chapterId, id, name, avatar }) => {
                    chapterMap[chapterId].participants.push({
                        id: id,
                        name: name,
                        avatar: avatar
                    });
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
            `SELECT id, token, title, intro, status,
                    default_audio AS defaultAudio,
                    default_background_image AS defaultBackgroundImage,
                    COALESCE(notes, '') AS notes
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
                Q.all(rows.map(row => this._getNarrationFiles(row.id))),
                Q.all(rows.map(row => this._getNarrationStyles(row.id)))
            ]).spread((chapterLists, characterLists, fileLists, styleLists) => ({
                narrations: chapterLists.map((chapters, i) => ({
                    narration: Object.assign(rows[i],
                                             {characters: characterLists[i],
                                              files: fileLists[i],
                                              styles: styleLists[i],
                                              intro: parseIntroText(rows[i].intro),
                                              introUrl: `${config.publicAddress}/narrations/${rows[i].token}/intro`}),
                    chapters: chapters
                }))
            }))
        ));
    }

    _getNarrationStyles(narrationId) {
        return Q.ninvoke(
            this.db,
            "all",
            `SELECT title_font AS titleFont, title_font_size AS titleFontSize,
                    title_color AS titleColor, title_shadow_color AS titleShadowColor,
                    body_text_font AS bodyTextFont,
                    body_text_font_size AS bodyTextFontSize,
                    body_text_color AS bodyTextColor,
                    body_text_background_color AS bodyTextBackgroundColor,
                    separator_image AS separatorImage
               FROM narration_styles
              WHERE narration_id = ?`,
            narrationId
        ).then(rows => (
            rows.length ? rows[0] : {}
        ));
    }

    getCharacterOverview(userId, opts) {
        const userOpts = Object.assign({ status: null }, opts);
        let extraQuery = "";
        let extraBinds = [];

        if (userOpts.status === "active") {
            const narrationGraceTime = new Date();
            narrationGraceTime.setDate(narrationGraceTime.getDate() - 14);

            extraQuery = "HAVING status = 'active' OR last_published > ?";
            extraBinds = [narrationGraceTime];
        }

        return Q.ninvoke(
            this.db,
            "all",
            `SELECT CHR.id, status,
                    COALESCE(MAX(published), NOW()) AS last_published
               FROM narrations N
               JOIN characters CHR ON CHR.narration_id = N.id
          LEFT JOIN chapters C ON C.narration_id = N.id
              WHERE player_id = ?
           GROUP BY CHR.id
                    ${extraQuery}
           ORDER BY last_published DESC`,
            [userId].concat(extraBinds)
        ).then(rows => (
            Q.all(rows.map(row => this.getFullCharacterStats(row.id)))
        ));
    }

    deleteNarration(id) {
        return Q.ninvoke(
            this.db,
            "run",
            "SELECT id FROM characters WHERE narration_id = ?",
            id
        ).then(characters => (
            Q.all(characters.map(char => (
                this.removeCharacter(char.id)
            )))
        )).then(() => (
            Q.ninvoke(
                this.db,
                "run",
                "DELETE FROM chapters WHERE narration_id = ?",
                id
            )
        )).then(() => (
            Q.ninvoke(
                this.db,
                "run",
                "DELETE FROM narrations WHERE id = ?",
                id
            )
        )).then(result => {
            // Delete the files
            const filesDir = path.join(config.files.path, id.toString());
            fs.removeSync(filesDir);

            // Return if there was a deleted narration in the above query
            return result.affectedRows === 1;
        });
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
                    `INSERT INTO chapter_participants (chapter_id, character_id)
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
              placeholderString = fields.map(_ => "?").join(", "),
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
                  ", C.player_id, U.display_name AS displayName, C.token, C.novel_token AS novelToken, C.notes" : "";

        return Q.ninvoke(
            this.db,
            "all",
            `SELECT C.id, C.name, C.avatar, C.description,
                    CASE WHEN C.player_id THEN TRUE ELSE FALSE END AS claimed
                    ${ extraFields }
               FROM characters C
               JOIN chapter_participants CP ON C.id = CP.character_id
          LEFT JOIN users U ON U.id = C.player_id
              WHERE chapter_id = ?`,
            chapterId
        ).then(participants => (
            participants.map(participant => (
                Object.assign(
                    participant,
                    { description: JSON.parse(participant.description),
                      claimed: !!participant.claimed }
                )
            ))
        ));
    }

    isCharacterParticipant(characterId, chapterId) {
        return Q.ninvoke(
            this.db,
            "query",
            `SELECT COUNT(*) AS cnt
               FROM chapter_participants
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
            `SELECT id, title, audio, narration_id as narrationId,
                    background_image AS backgroundImage,
                    main_text AS text, published
               FROM chapters
              WHERE id = ?`,
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

    _updateChapterParticipants(id, newParticipantList) {
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
                    this._addParticipant(id, newParticipant.id);
                }
            });

            currentParticipantList.forEach(currentParticipant => {
                if (!newHash.hasOwnProperty(currentParticipant.id)) {
                    this._removeParticipant(id, currentParticipant.id);
                }
            });
        });
    }

    updateChapter(id, props) {
        const participants = props.participants;
        delete props.participants;
        if ("text" in props) {
            props.text = JSON.stringify(props.text);
        }

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
            () => this._updateChapterParticipants(id, participants)
        ).then(
            () => this.getChapter(id, { includePrivateFields: true })
        );
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

    getCharacterInfoById(characterId, extraFields) {
        extraFields = extraFields || [];
        const extraFieldString = extraFields.length !== 0 ?
              `, ${ extraFields.join(", ") }` :
              "";

        return Q.ninvoke(
            this.db,
            "get",
            `SELECT id, name, token, notes, narration_id AS narrationId${ extraFieldString }
               FROM characters WHERE id = ?`,
            characterId
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
               FROM characters C
          LEFT JOIN users U
                 ON C.player_id = U.id
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
        const newNovelToken = generateToken();

        return Q.ninvoke(
            this.db,
            "run",
            `INSERT INTO characters (name, token, novel_token, player_id, narration_id)
                             VALUES (?, ?, ?, ?, ?)`,
            [name, newToken, newNovelToken, userId, narrationId]
        ).then(() => (
            this.getCharacterInfo(newToken)
        ));
    }

    _addParticipant(chapterId, characterId) {
        return this.getChapter(chapterId).then(() => (
            this.getChapterParticipants(chapterId)
        )).then(participants => {
            if (participants.some(p => p.id === characterId)) {
                return participants;
            }

            return Q.ninvoke(
                this.db,
                "run",
                `INSERT INTO chapter_participants (chapter_id, character_id)
                    VALUES (?, ?)`,
                [chapterId, characterId]
            );
        });
    }

    _removeParticipant(chapterId, characterId) {
        return Q.ninvoke(
            this.db,
            "run",
            `DELETE FROM chapter_participants
                  WHERE chapter_id = ? AND character_id = ?`,
            [chapterId, characterId]
        );
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
        const placeholders = messageIds.map(_ => "?").join(", ");

        return Q.ninvoke(
            this.db,
            "all",
            `SELECT MD.message_id AS messageId,
                        MD.recipient_id AS recipientId,
                        C.name, C.avatar
                   FROM message_deliveries MD JOIN characters C
                     ON MD.recipient_id = C.id
                  WHERE message_id IN (${ placeholders })`,
            messageIds
        ).then(deliveries => {
            const deliveryMap = {};
            deliveries.forEach(({ messageId, recipientId, name, avatar }) => {
                deliveryMap[messageId] = deliveryMap[messageId] || [];
                deliveryMap[messageId].push({ id: recipientId,
                                              name: name,
                                              avatar: avatar });
            });

            messages.forEach(message => {
                message.recipients = deliveryMap[message.id];
            });

            return messages;
        }).then(messages => {
            const placeholders = messages.map(_ => "?");

            return Q.ninvoke(
                this.db,
                "all",
                `SELECT id, name, avatar FROM characters
                      WHERE id IN (${ placeholders })`,
                messages.map(m => m.senderId)
            ).then(characters => {
                const characterMap = {};
                characters.forEach(c => {
                    characterMap[c.id] = {id: c.id,
                                          name: c.name,
                                          avatar: c.avatar};
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
               JOIN chapter_participants CP
                 ON (CP.chapter_id = CHPT.id AND
                     CP.character_id = CHR.id)
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
            `SELECT CHPT.id, CHPT.title,
                    CHPT.main_text AS text
               FROM chapters CHPT
               JOIN characters CHR
                 ON CHPT.narration_id = CHR.narration_id
               JOIN (SELECT MAX(CHAP.published) AS published, character_id
                       FROM chapter_participants CP
                       JOIN chapters CHAP
                         ON CP.chapter_id = CHAP.id
                      WHERE narration_id = ?
                            ${ extraWhereClause }
                   GROUP BY character_id) AS reaction_per_character
                 ON reaction_per_character.published = CHPT.published
                AND reaction_per_character.character_id = CHR.id
              WHERE CHR.narration_id = ?
                AND CHPT.published IS NOT NULL
           GROUP BY CHPT.id`,
            binds
        ).then(lastChapters => {
            const chapterIds = lastChapters.map(c => c.id);

            return Q.all(
                chapterIds.map(id => this.getAllChapterMessages(id))
            ).then(lastChapterMessages => {
                lastChapterMessages.forEach((messages, i) => {
                    lastChapters[i].messages = messages;
                });

                return Q.all(
                    chapterIds.map(id => this.getChapterParticipants(id))
                );
            }).then(lastChapterParticipants => {
                lastChapterParticipants.forEach((participants, i) => {
                    lastChapters[i].participants = participants;
                });

                return lastChapters;
            });
        });
    }

    getCharacterChaptersBasic(characterId) {
        return Q.ninvoke(
            this.db,
            "all",
            `SELECT C.id, C.title
                   FROM chapters C
                   JOIN chapter_participants CP
                     ON C.id = CP.chapter_id
                  WHERE published IS NOT NULL
                    AND CP.character_id = ?`,
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
               JOIN chapter_participants CP
                 ON C.id = CP.chapter_id
              WHERE published IS NOT NULL
                AND CP.character_id = ?`,
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
                `SELECT C.id, C.name, C.token, C.avatar, C.description,
                        C.backstory, C.novel_token AS novelToken, C.notes,
                        U.display_name AS displayName,
                        N.id AS narrationId, N.title AS narrationTitle,
                        N.status
                   FROM characters C
                   JOIN narrations N
                     ON C.narration_id = N.id
              LEFT JOIN users U
                     ON C.player_id = U.id
                  WHERE C.id = ?`,
                characterId
            ),
            this.getCharacterChaptersBasic(characterId)
        ]).spread((basicStats, chapters) => {
            return this._getPublicNarrationCharacters(basicStats.narrationId).then(characters => ({
                id: basicStats.id,
                token: basicStats.token,
                displayName: basicStats.displayName,
                name: basicStats.name,
                avatar: basicStats.avatar,
                novelToken: basicStats.novelToken,
                description: JSON.parse(basicStats.description),
                backstory: JSON.parse(basicStats.backstory),
                notes: basicStats.notes,
                narration: {
                    id: basicStats.narrationId,
                    title: basicStats.narrationTitle,
                    status: basicStats.status,
                    chapters: chapters,
                    characters: characters.filter(character => (
                        character.id !== basicStats.id
                    ))
                }
            }));
        });
    }

    resetCharacterToken(characterId) {
        const newToken = generateToken();

        return Q.ninvoke(
            this.db,
            "run",
            'UPDATE characters SET token = ? WHERE id = ?',
            [newToken, characterId]
        ).then(() => (
            this.getCharacterInfo(newToken)
        ));
    }

    updateCharacter(characterId, props) {
        const propNames = Object.keys(props).map(convertToDb),
              propNameStrings = propNames.map(p => `${p} = ?`);
        const propValues = Object.keys(props).map(p => (
            (["description", "backstory"].indexOf(p) !== -1) ?
                ((typeof props[p] === "string") ?
                 props[p] : JSON.stringify(props[p])) :
                props[p]
        ));

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
                    "run",
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
            `SELECT C.id AS characterId,
                    C.narration_id AS narrationId
               FROM characters C
              WHERE C.novel_token = ?`,
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

    searchNarration(narrationId, searchTerms) {
        return Q.ninvoke(
            this.db,
            "query",
            `SELECT id, title
               FROM chapters
              WHERE narration_id = ?
                AND (main_text LIKE ? OR title LIKE ?)
                AND published IS NOT NULL`,
            [narrationId, `%${searchTerms}%`, `%${searchTerms}%`]
        ).spread(results => (
            results.map(result => ({
                id: result.id,
                title: result.title
            }))
        ));
    }

    claimCharacter(characterId, userId) {
        return Q.ninvoke(
            this.db,
            "query",
            `SELECT id, name, narration_id, player_id
               FROM characters
              WHERE player_id = ?
                AND narration_id = (SELECT narration_id
                                      FROM characters
                                     WHERE id = ?)`,
            [userId, characterId]
        ).spread(results => {
            // Don't allow claiming more than one character per player
            // in the same narration
            if (results.length > 0) {
                throw new Error(
                    "Cannot claim more than one character in the same " +
                        "narration"
                );
            }

            // Yes, possibility of race condition here, but... MySQL
            return Q.ninvoke(
                this.db,
                "run",
                `UPDATE characters SET player_id = ?
                  WHERE id = ?
                    AND player_id IS NULL`,
                [userId, characterId]
            );
        }).then(() => (
            Q.ninvoke(
                this.db,
                "query",
                `SELECT player_id FROM characters WHERE id = ?`,
                [characterId]
            ).spread(results => {
                if (results[0].player_id === userId) {
                    return results[0].player_id;
                } else {
                    throw new Error(
                        `Could not claim character ${characterId} ` +
                            `with user id ${userId} (claimed by ` +
                            `${results[0].player_id})`
                    );
                }
            })
        ));
    }

    unclaimCharacter(characterId) {
        return Q.ninvoke(
            this.db,
            "query",
            `UPDATE characters
                SET player_id = NULL
              WHERE id = ?`,
            [characterId]
        ).then(() => (
            this.resetCharacterToken(characterId)
        ));
    }

    removeCharacter(characterId) {
        return Q.ninvoke(
            this.db,
            "run",
            `DELETE FROM messages WHERE sender_id = ?`,
            [characterId]
        ).then(() => (
            Q.ninvoke(
                this.db,
                "run",
                `DELETE FROM characters WHERE id = ?`,
                [characterId]
            )
        )).then(result => (
            result.affectedRows === 1
        ));
    }
}

export default NarrowsStore;
