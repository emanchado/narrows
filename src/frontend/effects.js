const http = require("choo/http");

const editor = require("./editor");
const extend = require("./extend");
const narrowsSchema = require("./narrows-schema");

module.exports = {
    getNarration: (data, state, send, done) => {
        const narrationUrl = "/api/narrations/" + data.narrationId;
        http(narrationUrl, (err, res, body) => {
            send("receiveNarrationData", JSON.parse(body), done);
        });
    },

    getNarrationFragments: (data, state, send, done) => {
        const narrationFragmentUrl = "/api/narrations/" +
                  data.narrationId + "/fragments";
        http(narrationFragmentUrl, (err, res, body) => {
            send("receiveNarrationFragmentsData", JSON.parse(body), done);
        });
    },

    getFragment: (data, state, send, done) => {
        const fragmentUrl = "/api/fragments/" + data.fragmentId;

        http(fragmentUrl, (err, res, body) => {
            const response = JSON.parse(body);
            const node = editor.importText(response.text);

            send("receiveFragmentData",
                 extend(response, { text: node }),
                 done);
        });
    },

    saveFragment: (data, state, send, done) => {
        const url = "/api/fragments/" + data.fragmentId;

        const xhr = new XMLHttpRequest();
        xhr.open("PUT", url);
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.addEventListener("load", function() {
            const response = JSON.parse(this.responseText);

            if (this.status >= 400) {
                alert("Could not save fragment text: " + response.errorMessage);
                return;
            }
        });
        const jsonDoc = state.editor.doc.toJSON();
        xhr.send(JSON.stringify({ title: state.fragment.title,
                                  text: jsonDoc }));
    },

    publishFragment: (data, state, send, done) => {
        const url = "/api/fragments/" + data.fragmentId;

        const xhr = new XMLHttpRequest();
        xhr.open("PUT", url);
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.addEventListener("load", function() {
            const response = JSON.parse(this.responseText);

            if (this.status >= 400) {
                alert("Could not publish fragment text: " + response.errorMessage);
                return;
            }
        });
        const jsonDoc = state.editor.doc.toJSON();
        xhr.send(JSON.stringify({ title: state.fragment.title,
                                  text: jsonDoc,
                                  published: true }));
    },

    saveNewFragment: (data, state, send, done) => {
        const url = "/api/narrations/" + data.narrationId + "/fragments";

        const xhr = new XMLHttpRequest();
        xhr.open("POST", url);
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.addEventListener("load", function() {
            const response = JSON.parse(this.responseText);

            if (this.status >= 400) {
                alert("Could not save fragment text: " + response.errorMessage);
                return;
            }

            send("location:setLocation", {location: "/fragments/" + response.id}, done);
        });
        const jsonDoc = state.editorNew.doc.toJSON();
        const characterIds = state.narration.characters.map(c => c.id);
        xhr.send(JSON.stringify({ title: state.fragment.title,
                                  text: jsonDoc,
                                  participants: characterIds }));
    },

    addImage: (data, state, send, done) => {
        const imageNodeType = narrowsSchema.schema.nodes.image,
              attrs = { src: data.src };

        state.editor.tr.replaceSelection(imageNodeType.create(attrs)).apply();
        done();
    },

    markTextForCharacter: (data, state, send, done) => {
        const characters = state.fragment.participants.filter(p => (
            state.mentionCharacters.includes(p.id)
        ));

        editor.markTextForCharacter(state.editor, characters);
        done();
    },

    addParticipant: (data, state, send, done) => {
        const url = "/api/fragments/" + state.fragment.id + "/participants";

        const xhr = new XMLHttpRequest();
        xhr.open("POST", url);
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.addEventListener("load", function() {
            const response = JSON.parse(this.responseText);

            if (this.status >= 400) {
                alert("Could not add participant: " + response.errorMessage);
                done();
                return;
            }

            send("addParticipantSuccess", data, done);
        });
        xhr.send(JSON.stringify(data.character));
    },

    removeParticipant: (data, state, send, done) => {
        const url = "/api/fragments/" + state.fragment.id +
                  "/participants/" + data.characterId;

        const xhr = new XMLHttpRequest();
        xhr.open("DELETE", url);
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.addEventListener("load", function() {
            const response = JSON.parse(this.responseText);

            if (this.status >= 400) {
                alert("Could not remove participant: " + response.errorMessage);
                done();
                return;
            }

            send("removeParticipantSuccess", data, done);
        });
        xhr.send();
    }
};
