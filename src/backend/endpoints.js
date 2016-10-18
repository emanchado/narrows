import path from "path";
import config from "config";
import Q from "q";
import formidable from "formidable";

import NarrowsStore from "./NarrowsStore";
import mentionFilter from "./mention-filter";
import messageUtils from "./message-utils";

const store = new NarrowsStore(config.db.path, config.files.path);
store.connect();

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

    store.getChapter(chapterId).then(chapterData => {
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

    store.getCharacterId(characterToken).then(characterId => {
        return store.getChapter(chapterId).then(chapterData => {
            if (!chapterData.published) {
                throw new Error("Unpublished chapter");
            }

            const participantIds = chapterData.participants.map(p => p.id);
            if (participantIds.indexOf(characterId) === -1) {
                throw new Error("Character does not participate in chapter");
            }

            chapterData.text =
                mentionFilter.filter(chapterData.text, characterId);

            store.getChapterReaction(chapterId, characterId).then(reaction => {
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
    if ("published" in req.body) {
        req.body.published = req.body.published ?
            (new Date().toISOString()) : null;
    }
    store.updateChapter(chapterId, req.body).then(chapter => {
        res.json(chapter);
    }).catch(err => {
        res.status(500).json({
            errorMessage: `There was a problem updating: ${ err }`
        });
    });
}

export function postNewChapter(req, res) {
    const narrationId = parseInt(req.params.narrId, 10);

    store.createChapter(narrationId, req.body).then(chapterData => {
        res.json(chapterData);
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

export function getStaticFile(req, res) {
    res.sendFile(path.join(req.params.narrId, req.params.filename),
                 { root: config.files.path });
}

export function putReactionCharacter(req, res) {
    const chapterId = req.params.chptId,
          characterToken = req.params.charToken,
          reactionText = req.body.text;

    store.getCharacterId(characterToken).then(characterId => {
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

    store.getCharacterId(characterToken).then(characterId => {
        return store.getChapterMessages(chapterId, characterId).then(messages => {
            res.json({
                messageThreads: messageUtils.threadMessages(messages),
                characterId: characterId
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

    store.getCharacterId(characterToken).then(characterId => {
        return store.addMessage(
            chapterId,
            characterId,
            messageText,
            messageRecipients
        ).then(() => {
            return store.getChapterMessages(chapterId, characterId);
        }).then(messages => {
            res.json({
                messageThreads: messageUtils.threadMessages(messages),
                characterId: characterId
            });
        });
    }).catch(err => {
        res.status(500).json({
            errorMessage: `Could not post message: ${ err }`
        });
    });
}

export function postChapterParticipants(req, res) {
    const chapterId = req.params.chptId,
          newParticipant = req.body;

    store.addParticipant(chapterId, newParticipant.id).then(participants => {
        res.json({ participants });
    }).catch(err => {
        res.status(500).json({
            errorMessage: `Could not add participant: ${ err }`
        });
    });
}

export function deleteChapterParticipant(req, res) {
    const chapterId = req.params.chptId,
          characterId = req.params.charId;

    store.removeParticipant(chapterId, characterId).then(participants => {
        res.json({ participants });
    }).catch(err => {
        res.status(500).json({
            errorMessage: `Could not remove participant: ${ err }`
        });
    });
}
