import path from "path";
import config from "config";
import Q from "q";
import formidable from "formidable";
import nodemailer from "nodemailer";
import sendmailTransport from "nodemailer-sendmail-transport";

import NarrowsStore from "./NarrowsStore";
import mentionFilter from "./mention-filter";
import messageUtils from "./message-utils";
import feeds from "./feeds";
import Mailer from "./Mailer";

const store = new NarrowsStore(config.db, config.files.path);
store.connect();
const transporter = nodemailer.createTransport(sendmailTransport());
const mailer = new Mailer(store, transporter);

export function getNarration(req, res) {
    const narrationId = parseInt(req.params.narrId, 10);

    store.getNarration(narrationId).then(narrationData => {
        res.json(narrationData);
    }).catch(err => {
        res.status(404).json({
            errorMessage: `Cannot find narration ${ narrationId }`
        });
    });
}

export function getChapter(req, res) {
    const chapterId = parseInt(req.params.chptId, 10);

    store.getChapter(chapterId, { includePrivateFields: true }).then(chapterData => {
        res.json(chapterData);
    }).catch(err => {
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
            if (!chapterData.published && !req.session.loggedIn) {
                throw new Error("Unpublished chapter");
            }

            const participantIds = chapterData.participants.map(p => p.id);
            if (participantIds.indexOf(charInfo.id) === -1) {
                throw new Error("Character does not participate in chapter");
            }

            chapterData.character = charInfo;
            chapterData.text =
                mentionFilter.filter(chapterData.text, charInfo.id);

            store.getChapterReaction(chapterId, charInfo.id).then(reaction => {
                chapterData.reaction = reaction;
                res.json(chapterData);
            });
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

    store.getNarrationChapters(narrationId).then(chapterListData => {
        res.json({ chapters: chapterListData });
    }).catch(err => {
        res.status(404).json({
            errorMessage: `Cannot find chapters for narration ${ narrationId }: ${ err }`
        });
    });
}

export function putChapter(req, res) {
    const chapterId = parseInt(req.params.chptId, 10);

    req.body.text = JSON.stringify(req.body.text);
    store.getChapter(chapterId).then(origChapter => {
        const origPublished = origChapter.published;

        return store.updateChapter(chapterId, req.body).then(chapter => {
            res.json(chapter);

            if (!origPublished && req.body.published) {
                mailer.chapterPublished(chapter);
            }
        });
    }).catch(err => {
        res.status(500).json({
            errorMessage: `There was a problem updating: ${ err }`
        });
    });
}

export function getChapterInteractions(req, res) {
    const chapterId = req.params.chptId;

    return Q.all([
        store.getChapter(chapterId, { includePrivateFields: true }),
        store.getAllChapterMessages(chapterId),
        store.getChapterReactions(chapterId)
    ]).spread((chapter, messages, reactions) => {
        res.json({
            chapter: chapter,
            messageThreads: messageUtils.threadMessages(messages),
            reactions: reactions
        });
    }).catch(err => {
        res.status(500).json({
            errorMessage: `Could not get interactions: ${ err }`
        });
    });
}

export function postChapterMessages(req, res) {
    const chapterId = req.params.chptId,
          messageText = req.body.text,
          messageRecipients = req.body.recipients || [];

    return store.addMessage(
        chapterId,
        null,
        messageText,
        messageRecipients
    ).then(() => (
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

    store.createChapter(narrationId, req.body).then(chapterData => {
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

export function postNarrationFiles(req, res) {
    const narrationId = parseInt(req.params.narrId, 10);

    const form = new formidable.IncomingForm();
    form.uploadDir = config.files.tmpPath;

    Q.ninvoke(form, "parse", req).spread(function(fields, files) {
        var uploadedFileInfo = files.file,
            filename = path.basename(uploadedFileInfo.name),
            tmpPath = uploadedFileInfo.path;

        return store.addMediaFile(narrationId, filename, tmpPath);
    }).then(fileInfo => {
        res.json(fileInfo);
    }).catch(err => {
        res.status(500).json({
            errorMessage: `Cannot add new media file: ${ err }`
        });
    });
}

function uploadFile(req, res, type) {
    const narrationId = parseInt(req.params.narrId, 10);

    const form = new formidable.IncomingForm();
    form.uploadDir = config.files.tmpPath;

    Q.ninvoke(form, "parse", req).spread(function(fields, files) {
        var uploadedFileInfo = files.file,
            filename = path.basename(uploadedFileInfo.name),
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

export function getChapterLastReactions(req, res) {
    const chapterId = parseInt(req.params.chptId, 10);

    store.getChapterLastReactions(chapterId).then(lastReactions => {
        res.json({ chapterId: chapterId,
                   lastReactions: lastReactions.map(reaction => (
                       { chapter: { id: reaction.chapterId,
                                    title: reaction.chapterTitle },
                         character: { id: reaction.characterId,
                                      name: reaction.characterName },
                         text: reaction.text }
                   )) });
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

export function putReactionCharacter(req, res) {
    const chapterId = req.params.chptId,
          characterToken = req.params.charToken,
          reactionText = req.body.text;

    store.getCharacterInfo(characterToken).then(({ id: characterId }) => {
        return store.updateReaction(chapterId, characterId, reactionText).then(() => {
            res.json({ chapterId, characterId, reactionText });
        });
    }).catch(err => {
        res.status(500).json({
            errorMessage: `Could not save reaction: ${ err }`
        });
    });
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

    // TODO: Check that the character really belongs to this narration

    store.getCharacterInfo(characterToken).then(characterInfo => {
        return store.addMessage(
            chapterId,
            characterInfo.id,
            messageText,
            messageRecipients
        ).then(() => {
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
        });
    }).catch(err => {
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
                `character ${ characterToken }: ${ err }`
        });
    });
}
