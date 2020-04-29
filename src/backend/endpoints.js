import path from "path";
import config from "config";
import Q from "q";
import formidable from "formidable";
import nodemailer from "nodemailer";
import sharp from "sharp";

import NarrowsStore from "./NarrowsStore";
import UserStore from "./UserStore";
import mentionFilter from "./mention-filter";
import messageUtils from "./message-utils";
import apiFormatter from "./api-formatter";
import feeds from "./feeds";
import Mailer from "./Mailer";
import { isValidEmail } from "./validation";
import objectSelect from "./objectSelect";

const store = new NarrowsStore(config.db, config.files.path);
store.connect();
const userStore = new UserStore(config.db);
userStore.connect();

const transporter = nodemailer.createTransport(config.mail.options);
const mailer = new Mailer(store, transporter);

export function getSession(req, res) {
    const userId = parseInt(req.session.userId, 10);

    if (userId) {
        userStore.getUser(userId).then(info => (
            res.json(info)
        )).catch(err => {
            res.status(404).json({});
        });
    } else {
        res.status(404).json({});
    }
}

export function postSession(req, res) {
    const email = req.body.email;
    const password = req.body.password;

    userStore.authenticate(email, password).then(userId => (
        userId ?
            userStore.getUser(userId).then(info => {
                req.session.userId = userId;
                res.json(info);
            })
            :
            res.status(404).json({notFound: true})
    )).catch(err => {
        res.status(500).json({error: err});
    });
}

export function deleteSession(req, res) {
    req.session.userId = null;
    res.status(204).json();
}

export function getNarrationArchive(req, res) {
    store.getNarrationOverview(req.session.userId).then(narrationOverviewData => {
        res.json(narrationOverviewData);
    }).catch(err => {
        res.status(500).json({
            errorMessage: `Cannot get narration archive for ` +
                `this user: ${ err }`
        });
    });
}

export function getCharacterArchive(req, res) {
    store.getCharacterOverview(req.session.userId).then(characters => {
        res.json({characters: characters});
    }).catch(err => {
        res.status(500).json({
            errorMessage: `Cannot get character archive for ` +
                `this user: ${ err }`
        });
    });
}

export function getNarrationOverview(req, res) {
    Q.all([
        store.getNarrationOverview(req.session.userId, { status: "active" }),
        store.getCharacterOverview(req.session.userId, { status: "active" })
    ]).spread((narrationOverviewData, characterOverviewData) => {
        res.json({
            narrations: narrationOverviewData.narrations,
            characters: characterOverviewData
        });
    }).catch(err => {
        res.status(500).json({
            errorMessage: `Cannot get narration overview for ` +
                `this user: ${ err }`
        });
    });
}

export function getNarration(req, res) {
    const narrationId = parseInt(req.params.narrId, 10);

    store.getNarration(narrationId).then(narrationData => {
        return userStore.canActAs(
            req.session.userId,
            narrationData.narratorId
        ).then(() => {
            res.json(narrationData);
        });
    }).catch(err => {
        res.status(404).json({
            errorMessage: `Cannot find narration ${ narrationId } for ` +
                `this user: ${ err }`
        });
    });
}

export function getNarrationByToken(req, res) {
    const narrationToken = req.params.narrToken;

    store.getNarrationByToken(narrationToken).then(narrationData => {
        res.json(narrationData);
    }).catch(err => {
        res.status(404).json({
            errorMessage: `Cannot find narration ${ narrationToken } by token `
        });
    });
}

export function putNarration(req, res) {
    const narrationId = parseInt(req.params.narrId, 10);
    const newProps = req.body;

    store.getNarration(narrationId).then(narrationData => (
        userStore.canActAs(
            req.session.userId,
            narrationData.narratorId
        ).then(() => (
            store.updateNarration(narrationId, newProps)
        ))
    )).then(narrationData => {
        res.json(narrationData);
    }).catch(err => {
        res.status(404).json({
            errorMessage: `Cannot update narration ${ narrationId } as ` +
                `this user: ${ err }`
        });
    });
}

export function postNarration(req, res) {
    const narratorId = req.session.userId;

    if (!req.body.title) {
        res.status(400).json({
            errorMessage: 'New narrations need at least a title'
        });
        return;
    }

    store.createNarration({
        narratorId: narratorId,
        title: req.body.title,
        defaultAudio: req.body.defaultAudio,
        defaultBackgroundImage: req.body.defaultBackgroundImage
    }).then(narrationData => {
        res.json(narrationData);
    }).catch(err => {
        res.status(400).json({
            errorMessage: `Cannot create narration: ${ err }`
        });
    });
}

export function deleteNarration(req, res) {
    const narrationId = parseInt(req.params.narrId, 10);
    const newProps = req.body;

    store.getNarration(narrationId).then(narrationData => (
        userStore.canActAs(
            req.session.userId,
            narrationData.narratorId
        ).then(() => (
            store.deleteNarration(narrationId, newProps)
        ))
    )).then(narrationData => {
        res.status(204).json();
    }).catch(err => {
        res.status(404).json({
            errorMessage: `Cannot delete narration ${ narrationId } as ` +
                `this user: ${ err }`
        });
    });
}

export function getChapter(req, res) {
    const chapterId = parseInt(req.params.chptId, 10);

    store.getChapter(chapterId, { includePrivateFields: true }).then(chapterData => (
        store.getNarration(chapterData.narrationId).then(narrationData => (
            userStore.canActAs(req.session.userId, narrationData.narratorId)
        )).then(() => (
            res.json(chapterData)
        ))
    )).catch(err => {
        res.status(404).json({
            errorMessage: `Cannot find chapter ${ chapterId }: ${ err }`
        });
    });
}

export function getChapterCharacter(req, res) {
    const chapterId = parseInt(req.params.chptId, 10);
    const characterToken = req.params.charToken;

    store.getCharacterInfo(characterToken).then(charInfo => {
        return store.getChapter(chapterId).then(chapterData => {
            if (!chapterData.published && !req.session.userId) {
                throw new Error("Unpublished chapter");
            }

            const participantIds = chapterData.participants.map(p => p.id);
            if (participantIds.indexOf(charInfo.id) === -1) {
                throw new Error("Character does not participate in chapter");
            }

            chapterData.character = charInfo;
            chapterData.text =
                mentionFilter.filter(chapterData.text, charInfo.id);

            res.json(chapterData);
        });
    }).catch(err => {
        res.status(404).json({
            errorMessage: `Cannot find chapter ${ chapterId }` +
                ` with character ${ characterToken }: ${ err }`
        });
    });
}

export function getNarrationChapters(req, res) {
    const narrationId = parseInt(req.params.narrId, 10);

    Q.all([
        store.getNarrationChapters(narrationId),
        store.getNarration(narrationId)
    ]).spread((chapterListData, narrationData) => {
        return userStore.canActAs(
            req.session.userId,
            narrationData.narratorId
        ).then(() => {
            res.json({ narration: narrationData, chapters: chapterListData });
        });
    }).catch(err => {
        res.status(404).json({
            errorMessage: `Cannot find chapters for narration ${ narrationId }: ${ err }`
        });
    });
}

export function putChapter(req, res) {
    const chapterId = parseInt(req.params.chptId, 10);
    const newProps = req.body;

    store.getChapter(chapterId).then(origChapter => (
        store.getNarration(origChapter.narrationId).then(narrationData => (
            userStore.canActAs(req.session.userId, narrationData.narratorId)
        )).then(() => {
            const origPublished = origChapter.published;

            return store.updateChapter(chapterId, newProps).then(chapter => {
                res.json(chapter);

                if (!origPublished && newProps.published) {
                    mailer.chapterPublished(chapter);
                }
            });
        })
    )).catch(err => {
        res.status(500).json({
            errorMessage: `There was a problem updating: ${ err }`
        });
    });
}

export function getChapterInteractions(req, res) {
    const chapterId = req.params.chptId;

    return Q.all([
        store.getChapter(chapterId, { includePrivateFields: true }),
        store.getAllChapterMessages(chapterId)
    ]).spread((chapter, messages) => (
        store.getNarration(chapter.narrationId).then(narrationData => (
            userStore.canActAs(req.session.userId, narrationData.narratorId)
        )).then(() => (
            res.json({
                chapter: chapter,
                messageThreads: messageUtils.threadMessages(messages)
            })
        ))
    )).catch(err => {
        res.status(500).json({
            errorMessage: `Could not get interactions: ${ err }`
        });
    });
}

export function postChapterMessages(req, res) {
    const chapterId = req.params.chptId,
          messageText = req.body.text,
          messageRecipients = req.body.recipients || [];

    return store.getChapter(chapterId).then(chapterData => (
        store.getNarration(chapterData.narrationId)
    )).then(narrationData => (
        userStore.canActAs(req.session.userId, narrationData.narratorId)
    )).then(() => (
        store.addMessage(
            chapterId,
            null,
            messageText,
            messageRecipients
        )
    )).then(() => (
        store.getAllChapterMessages(chapterId)
    )).then(messages => {
        res.json({
            messageThreads: messageUtils.threadMessages(messages)
        });

        mailer.messagePosted({chapterId: chapterId,
                              sender: {id: null, name: "Narrator"},
                              text: messageText,
                              recipients: messageRecipients});
    }).catch(err => {
        res.status(500).json({
            errorMessage: `Could not post message: ${ err }`
        });
    });
}

export function postNewChapter(req, res) {
    const narrationId = parseInt(req.params.narrId, 10);

    store.getNarration(narrationId).then(narrationData => (
        userStore.canActAs(req.session.userId, narrationData.narratorId)
    )).then(() => (
        store.createChapter(narrationId, req.body)
    )).then(chapterData => {
        res.json(chapterData);

        if (chapterData.published) {
            mailer.chapterPublished(chapterData);
        }
    }).catch(err => {
        res.status(500).json({
            errorMessage: `There was a problem: ${ err }`
        });
    });
}

function uploadFile(req, res, type) {
    const narrationId = parseInt(req.params.narrId, 10);

    const form = new formidable.IncomingForm();
    form.uploadDir = config.files.tmpPath;

    store.getNarration(narrationId).then(narrationData => (
        userStore.canActAs(req.session.userId, narrationData.narratorId)
    )).then(() => (
        Q.ninvoke(form, "parse", req)
    )).spread(function(fields, files) {
        const uploadedFileInfo = files.file;

        if (!uploadedFileInfo) {
            throw new Error("No file given");
        }

        const filename = path.basename(uploadedFileInfo.name),
              tmpPath = uploadedFileInfo.path;

        return store.addMediaFile(narrationId, filename, tmpPath, type);
    }).then(fileInfo => {
        res.json(fileInfo);
    }).catch(err => {
        res.status(500).json({
            errorMessage: `Cannot add new media file: ${ err }`
        });
    });
}

export function postNarrationImages(req, res) {
    uploadFile(req, res, "images");
}

export function postNarrationBackgroundImages(req, res) {
    uploadFile(req, res, "backgroundImages");
}

export function postNarrationAudio(req, res) {
    uploadFile(req, res, "audio");
}

export function postNarrationCharacters(req, res) {
    const narrationId = parseInt(req.params.narrId, 10),
          name = req.body.name || "Unnamed character",
          email = req.body.email;

    let promise;
    if (email) {
        if (!isValidEmail(email)) {
            res.status(400).json({
                errorMessage: `'${ email }' is not a valid e-mail`
            });
            return;
        }

        promise = userStore.getUserByEmail(email).catch(() => (
            userStore.createUser({ email: email }).then(() => (
                userStore.getUserByEmail(email)
            ))
        )).then(user => user.id);
    } else {
        promise = Q(null);
    }

    promise.then(userId => (
        store.addCharacter(name, userId, narrationId)
    )).then(character => (
        res.json(character)
    )).catch(err => {
        res.status(500).json({
            errorMessage: `Cannot add character to narration: ${ err }`
        });
    });
}

export function getNarrationLastReactions(req, res) {
    const narrationId = parseInt(req.params.narrId, 10);

    store.getNarration(narrationId).then(narrationData => (
        userStore.canActAs(req.session.userId, narrationData.narratorId)
    )).then(() => (
        store.getNarrationLastReactions(narrationId)
    )).then(lastChapters => {
        res.json(apiFormatter.formatLastReactions(lastChapters));
    }).catch(err => {
        res.status(500).json({
            errorMessage: `Cannot get last reactions: ${ err }`
        });
    });
}

export function getChapterLastReactions(req, res) {
    const chapterId = parseInt(req.params.chptId, 10);

    store.getChapter(chapterId).then(chapterData => (
        store.getNarration(chapterData.narrationId)
    )).then(narrationData => (
        userStore.canActAs(req.session.userId, narrationData.narratorId)
    )).then(() => (
        store.getChapterLastReactions(chapterId)
    )).then(lastChapters => {
        res.json(apiFormatter.formatLastReactions(lastChapters));
    }).catch(err => {
        res.status(500).json({
            errorMessage: `Cannot get last reactions: ${ err }`
        });
    });
}

export function getStaticFile(req, res) {
    res.sendFile(path.join(req.params.narrId, req.params.filename),
                 { root: config.files.path });
}

export function getMessagesCharacter(req, res) {
    const chapterId = req.params.chptId,
          characterToken = req.params.charToken;

    store.getCharacterInfo(characterToken).then(characterInfo => {
        return store.getChapterMessages(chapterId, characterInfo.id).then(messages => {
            res.json({
                messageThreads: messageUtils.threadMessages(messages),
                characterId: characterInfo.id
            });
        });
    }).catch(err => {
        res.status(500).json({
            errorMessage: `Could not get messages: ${ err }`
        });
    });
}

export function postMessageCharacter(req, res) {
    const chapterId = req.params.chptId,
          characterToken = req.params.charToken,
          messageText = req.body.text,
          messageRecipients = req.body.recipients || [];

    store.getCharacterInfo(characterToken).then(characterInfo => (
        store.isCharacterParticipant(characterInfo.id, chapterId).then(isParticipant => {
            if (!isParticipant) {
                throw new Error("Character does not participate in chapter");
            }

            return store.addMessage(
                chapterId,
                characterInfo.id,
                messageText,
                messageRecipients
            );
        }).then(() => {
            return store.getChapterMessages(chapterId, characterInfo.id);
        }).then(messages => {
            res.json({
                messageThreads: messageUtils.threadMessages(messages),
                characterId: characterInfo.id
            });

            mailer.messagePosted({chapterId: chapterId,
                                  sender: characterInfo,
                                  text: messageText,
                                  recipients: messageRecipients});
        })
    )).catch(err => {
        res.status(500).json({
            errorMessage: `Could not post message: ${ err }`
        });
    });
}

export function getFeedsCharacter(req, res) {
    const characterToken = req.params.charToken;

    store.getCharacterInfo(characterToken).then(characterInfo => {
        const { id: characterId, name: characterName } = characterInfo;
        const baseUrl = req.protocol + "://" + req.get("host");

        return feeds.makeCharacterFeed(baseUrl, characterInfo, store);
    }).then(feedXml => {
        res.set("Content-Type", "application/rss+xml");
        res.send(feedXml);
    }).catch(err => {
        res.status(500).json({
            errorMessage: `Could not create feed: ${ err }`
        });
    });
}

export function putNotesCharacter(req, res) {
    const characterToken = req.params.charToken;
    const newNotes = req.body.notes;

    store.getCharacterInfo(characterToken).then(character => {
        store.saveCharacterNotes(character.id, newNotes).then(() => {
            character.notes = newNotes;
            res.json(character);
        }).catch(err => {
            res.status(500).json({
                errorMessage: `Could not save notes: ${ err }`
            });
        });
    }).catch(err => {
        res.status(500).json({
            errorMessage: `Could not save notes for non-existent ` +
                `character ${ characterToken }`
        });
    });
}

export function getCharacter(req, res) {
    const characterToken = req.params.charToken;

    return store.getCharacterInfo(characterToken).then(character => (
        store.getFullCharacterStats(character.id).then(stats => {
            res.json(stats);
        })
    )).catch(err => {
        res.status(500).json({
            errorMessage: `Could not get full character stats for ` +
                `character '${ characterToken }': ${ err }`
        });
    });
}

export function putCharacter(req, res) {
    const characterToken = req.params.charToken;
    const newProps = objectSelect(
        req.body,
        ["name", "description", "backstory", "notes"]
    );

    return store.getCharacterInfo(characterToken).then(character => (
        store.updateCharacter(character.id, newProps).then(newCharacter => {
            res.json(newCharacter);
        })
    )).catch(err => {
        res.status(500).json({
            errorMessage: `Could not update character with ` +
                `id '${ characterToken }': ${ err }`
        });
    });
}

export function putCharacterById(req, res) {
    const characterId = parseInt(req.params.charId, 10);
    const newProps = objectSelect(
        req.body,
        ["name", "description", "backstory", "notes"]
    );

    return store.updateCharacter(characterId, newProps).then(newCharacter => {
        if (!("email" in req.body)) {
            return newCharacter;
        }

        const email = req.body.email;
        if (email) {
            return userStore.getUserByEmail(email).catch(() => (
                userStore.createUser({ email: email }).then(() => (
                    userStore.getUserByEmail(email)
                ))
            )).then(playerUser => (
                store.updateCharacter(characterId, {
                    playerId: playerUser.id
                })
            ));
        } else {
            return store.updateCharacter(characterId, { playerId: null });
        }
    }).then(updatedCharacter => {
        res.json(updatedCharacter);
    }).catch(err => {
        res.status(500).json({
            errorMessage: `Could not update character with ` +
                `id '${ characterId }': ${ err }`
        });
    });
}

export function deleteCharacterById(req, res) {
    const characterId = parseInt(req.params.charId, 10);

    return store.getCharacterInfoById(characterId, ["narration_id"]).then(character => (
        store.getNarration(character.narration_id)
    )).then(narration => (
        userStore.canActAs(req.session.userId, narration.narratorId)
    )).then(() => (
        store.removeCharacter(characterId)
    )).then(success => {
        if (success) {
            res.status(204).json();
        } else {
            res.status(404).json({
                errorMessage: `Cannot find character with id '${ characterId }'`
            });
        }
    }).catch(err => {
        res.status(500).json({
            errorMessage: `Cannot delete character with ` +
                `id '${ characterId }': ${ err }`
        });
    });
}

export function putCharacterAvatar(req, res) {
    const characterToken = req.params.charToken;
    const form = new formidable.IncomingForm();
    form.uploadDir = config.files.tmpPath;

    return Q.all([
        store.getCharacterInfo(characterToken),
        Q.ninvoke(form, "parse", req)
    ]).spread((character, [fields, files]) => {
        const filename = path.basename(files.avatar.name);
        const resizedPath = `${ files.avatar.path }-resized`;

        // Resize image
        return Q.ninvoke(
            sharp(files.avatar.path).resize(100, 100),
            "toFile",
            resizedPath
        ).then(() => (
            store.updateCharacterAvatar(character.id, filename, resizedPath)
        )).then(fullCharacter => {
            res.json(fullCharacter);
        });
    }).catch(err => {
        res.status(500).json({
            errorMessage: `Could not update character with ` +
                `id '${ characterToken }': ${ err }`
        });
    });
}

export function getUsers(req, res) {
    return userStore.getUsers().then(users => (
        res.json({ users: users })
    )).catch(err => {
        res.status(500).json({
            errorMessage: `There was a problem getting the users: ${ err }`
        });
    });
}

export function postUser(req, res) {
    const props = req.body;

    if (!isValidEmail(props.email)) {
        res.status(400).json({
            errorMessage: `'${ props.email }' is not a valid e-mail`
        });
        return;
    }

    userStore.createUser(props).then(user => (
        res.json(user)
    )).catch(err => {
        res.status(500).json({
            errorMessage: `There was a problem creating the new user: ${ err }`
        });
    });
}

export function putUser(req, res) {
    const userId = parseInt(req.params.userId, 10);
    const newProps = req.body;

    userStore.canActAs(req.session.userId, userId).then(() => {
        userStore.updateUser(userId, newProps).then(user => {
            res.json(user);
        }).catch(err => {
            res.status(500).json({
                errorMessage: `There was a problem updating: ${ err }`
            });
        });
    }).catch(err => {
        res.status(403).json({
            errorMessage: `Cannot modify user ${ userId }`
        });
    });
}

export function getNovel(req, res) {
    const novelToken = req.params.novelToken;

    store.getNovelInfo(novelToken).then(({narrationId, characterId}) => (
        Q.all([
            store.getPublicNarration(narrationId),
            store.getCharacterChapters(characterId)
        ]).spread((narration, chapters) => {
            chapters.forEach(c => {
                c.text =
                    mentionFilter.filter(c.text, characterId);
            });

            return res.json({
                token: novelToken,
                characterId: characterId,
                narration: narration,
                chapters: chapters
            });
        })
    )).catch(err => {
        res.status(500).json({
            errorMessage: `There was a problem updating: ${ err }`
        });
    });
}

export function postPasswordReset(req, res) {
    const email = req.body.email;

    userStore.makePasswordResetLink(email).then(passwordResetLink => {
        mailer.passwordReset(email, passwordResetLink);
    }).catch(err => {
        // We shouldn't say whether or not an e-mail is registered
    }).then(() => {
        res.json({ email: email });
    });
}

export function getCharacterById(req, res) {
    const characterId = parseInt(req.params.charId, 10);

    return store.getFullCharacterStats(characterId).then(stats => {
        res.json(stats);
    }).catch(err => {
        res.status(500).json({
            errorMessage: `Could not get full character stats for ` +
                `character '${ characterId }': ${ err }`
        });
    });
}

export function postCharacterByIdToken(req, res) {
    const characterId = parseInt(req.params.charId, 10);

    return store.resetCharacterToken(characterId).then(newCharacter => {
        res.json(newCharacter);
    }).catch(err => {
        res.status(500).json({
            errorMessage: `Could not reset character token for ` +
                `character '${ characterId }': ${ err }`
        });
    });
}

export function getNarrationChapterSearch(req, res) {
    const narrationId = parseInt(req.params.narrId, 10);
    const searchTerms = req.query.terms;

    store.getNarration(narrationId).then(narrationData => (
        userStore.canActAs(req.session.userId, narrationData.narratorId)
    )).then(() => (
        store.searchNarration(narrationId, searchTerms)
    )).then(chapters => {
        res.json({ results: chapters });
    }).catch(err => {
        res.status(500).json({
            errorMessage: `Cannot search: ${ err }`
        });
    });
}

export function postCharacterClaim(req, res) {
    const characterId = parseInt(req.params.charId, 10);
    const email = req.body.email;

    return userStore.getUserByEmail(email).catch(() => (
        userStore.createUser({ email: email }).then(() => (
            userStore.getUserByEmail(email)
        ))
    )).then(user => (
        store.claimCharacter(characterId, user.id)
    )).then(() => (
        store.updateCharacter(characterId, { introSent: new Date() })
    )).then(() => (
        store.getCharacterInfoById(characterId, ["narration_id"]).then(character => (
            store.getNarration(character.narration_id).then(narration => (
                userStore.getUser(narration.narratorId).then(narrator => {
                    narration.narrator = narrator;
                    mailer.characterClaimed(email, narration, character);
                })
            )).then(() => {
                res.json({
                    id: characterId,
                    email: email
                });
            })
        ))
    )).catch(err => {
        res.status(400).json({
            errorMessage: `Could not claim character ${characterId}: ${ err }`
        });
    });
}
