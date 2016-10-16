import path from "path";
import config from "config";
import Q from "q";
import formidable from "formidable";

import NarrowsStore from "./NarrowsStore";
import mentionFilter from "./mention-filter";

const store = new NarrowsStore(config.db.path, config.files.path);
store.connect();

export function getNarration(req, res) {
    const narrationId = parseInt(req.params.narrId, 10);

    store.getNarration(narrationId).then(narrationData => {
        res.json(narrationData);
    }).catch(err => {
        res.statusCode = 404;
        res.json({ errorMessage: "Cannot find narration " + narrationId });
    });
}

export function getFragment(req, res) {
    const fragmentId = parseInt(req.params.fgmtId, 10);

    store.getFragment(fragmentId).then(fragmentData => {
        res.json(fragmentData);
    }).catch(err => {
        res.statusCode = 404;
        res.json({
            errorMessage: `Cannot find fragment ${ fragmentId }: ${ err }`
        });
    });
}

export function getFragmentCharacter(req, res) {
    const fragmentId = parseInt(req.params.fgmtId, 10);
    const characterToken = req.params.charToken;

    store.getCharacterId(characterToken).then(characterId => {
        return store.getFragment(fragmentId).then(fragmentData => {
            if (!fragmentData.published) {
                throw new Error("Unpublished fragment");
            }

            const participantIds = fragmentData.participants.map(p => p.id);
            if (participantIds.indexOf(characterId) === -1) {
                throw new Error("Character does not participate in fragment");
            }

            fragmentData.text =
                mentionFilter.filter(fragmentData.text, characterId);

            store.getFragmentReaction(fragmentId, characterId).then(reaction => {
                fragmentData.reaction = reaction;
                res.json(fragmentData);
            });
        });
    }).catch(err => {
        res.statusCode = 404;
        res.json({
            errorMessage: `Cannot find fragment ${ fragmentId }` +
                ` with character ${ characterToken }: ${ err }`
        });
    });
}

export function getNarrationFragments(req, res) {
    const narrationId = parseInt(req.params.narrId, 10);

    store.getNarrationFragments(narrationId).then(fragmentListData => {
        res.json({ fragments: fragmentListData });
    }).catch(err => {
        res.statusCode = 404;
        res.json({
            errorMessage: `Cannot find fragments for narration ${ narrationId }: ${ err }`
        });
    });
}

export function putFragment(req, res) {
    const fragmentId = parseInt(req.params.fgmtId, 10);

    req.body.text = JSON.stringify(req.body.text);
    if ("published" in req.body) {
        req.body.published = req.body.published ?
            (new Date().toISOString()) : null;
    }
    store.updateFragment(fragmentId, req.body).then(fragment => {
        res.json(fragment);
    }).catch(err => {
        res.statusCode = 500;
        res.json({
            errorMessage: `There was a problem updating: ${ err }`
        });
    });
}

export function postNewFragment(req, res) {
    const narrationId = parseInt(req.params.narrId, 10);

    store.createFragment(narrationId, req.body).then(fragmentData => {
        res.json(fragmentData);
    }).catch(err => {
        res.statusCode = 500;
        res.json({
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
        res.statusCode = 500;
        res.json({
            errorMessage: `Cannot add new media file: ${ err }`
        });
    });
}

export function getStaticFile(req, res) {
    res.sendFile(path.join(req.params.narrId, req.params.filename),
                 { root: config.files.path });
}

export function putReaction(req, res) {
    const fragmentId = req.params.fgmtId,
          characterToken = req.params.charToken,
          reactionText = req.body.text;

    store.getCharacterId(characterToken).then(characterId => {
        return store.updateReaction(fragmentId, characterId, reactionText).then(() => {
            res.json({ fragmentId, characterId, reactionText });
        });
    }).catch(err => {
        res.statusCode = 500;
        res.json({ errorMessage: "Could not save reaction: " + err});
    });
}

export function postFragmentParticipants(req, res) {
    const fragmentId = req.params.fgmtId,
          newParticipant = req.body;

    store.addParticipant(fragmentId, newParticipant.id).then(participants => {
        res.json({ participants });
    }).catch(err => {
        res.statusCode = 500;
        res.json({ errorMessage: "Could not add participant: " + err});
    });
}

export function deleteFragmentParticipant(req, res) {
    const fragmentId = req.params.fgmtId,
          characterId = req.params.charId;

    store.removeParticipant(fragmentId, characterId).then(participants => {
        res.json({ participants });
    }).catch(err => {
        res.statusCode = 500;
        res.json({ errorMessage: "Could not remove participant: " + err});
    });
}
