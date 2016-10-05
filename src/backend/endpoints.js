import path from "path";
import config from "config";

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
                ` with character ${ characterToken }`
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

export function postFragment(req, res) {
    const fragmentId = parseInt(req.params.fgmtId, 10);

    req.body.text = JSON.stringify(req.body.text);
    if ("published" in req.body) {
        req.body.published = req.body.published ?
            (new Date().toISOString()) : null;
    }
    store.updateFragment(fragmentId, req.body).then(fragment => {
        res.send(fragment);
    }).catch(err => {
        res.send("There was a problem updating: " + err);
    });
}

export function postNewFragment(req, res) {
    const narrationId = parseInt(req.params.narrId, 10);

    req.body.text = JSON.stringify(req.body.text);
    store.createFragment(narrationId, req.body).then(fragmentData => {
        res.json(fragmentData);
    }).catch(err => {
        res.send("There was a problem: " + err);
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
