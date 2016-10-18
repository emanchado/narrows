const http = require("choo/http");

const editor = require("./editor");
const extend = require("./extend");
const narrowsSchema = require("./narrows-schema");

function updateChapter(chapter, editor, done, extra) {
    extra = extra || {};

    const url = "/api/chapters/" + chapter.id;
    const xhr = new XMLHttpRequest();
    xhr.open("PUT", url);
    xhr.setRequestHeader("Content-Type", "application/json");
    xhr.addEventListener("load", function() {
        const response = JSON.parse(this.responseText);

        if (this.status >= 400) {
            alert("Could not publish chapter text: " + response.errorMessage);
        }

        done();
    });
    const jsonDoc = editor.doc.toJSON();

    const update = {
        title: chapter.title,
        text: jsonDoc,
        audio: chapter.audio,
        backgroundImage: chapter.backgroundImage
    };
    xhr.send(JSON.stringify(extend(update, extra)));
}

module.exports = {
    getNarration: (data, state, send, done) => {
        const narrationUrl = "/api/narrations/" + data.narrationId;
        http(narrationUrl, (err, res, body) => {
            send("receiveNarrationData", JSON.parse(body), done);
        });
    },

    getNarrationChapters: (data, state, send, done) => {
        const narrationChapterUrl = "/api/narrations/" +
                  data.narrationId + "/chapters";
        http(narrationChapterUrl, (err, res, body) => {
            send("receiveNarrationChaptersData", JSON.parse(body), done);
        });
    },

    getChapter: (data, state, send, done) => {
        const chapterUrl = "/api/chapters/" + data.chapterId;

        http(chapterUrl, (err, res, body) => {
            const response = JSON.parse(body);
            const node = editor.importText(response.text);

            send("receiveChapterData",
                 extend(response, { text: node }),
                 done);
        });
    },

    saveChapter: (data, state, send, done) => {
        updateChapter(state.chapter,
                       state.editor,
                       done);
    },

    publishChapter: (data, state, send, done) => {
        updateChapter(state.chapter,
                       state.editor,
                       done,
                       { published: true });
    },

    saveNewChapter: (data, state, send, done) => {
        const url = "/api/narrations/" + data.narrationId + "/chapters";

        const xhr = new XMLHttpRequest();
        xhr.open("POST", url);
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.addEventListener("load", function() {
            const response = JSON.parse(this.responseText);

            if (this.status >= 400) {
                alert("Could not save chapter text: " + response.errorMessage);
                return;
            }

            send("location:setLocation", {location: "/chapters/" + response.id}, done);
        });
        const jsonDoc = state.editorNew.doc.toJSON();
        const characterIds = state.narration.characters.map(c => c.id);
        xhr.send(JSON.stringify({ title: state.chapter.title,
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
        const characters = state.chapter.participants.filter(p => (
            state.mentionCharacters.includes(p.id)
        ));

        editor.markTextForCharacter(state.editor, characters);
        done();
    },

    addParticipant: (data, state, send, done) => {
        const url = "/api/chapters/" + state.chapter.id + "/participants";

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
        const url = "/api/chapters/" + state.chapter.id +
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
    },

    playPausePreview: (data, state, send, done) => {
        const audioEl = document.getElementById(data.id);

        if (audioEl.paused) {
            audioEl.play();
        } else {
            audioEl.pause();
        }

        done();
    },

    chooseMediaFile: (data, state, send, done) => {
        const fileInput = document.getElementById("new-media-file");

        fileInput.click();
    },

    addMediaFile: (data, state, send, done) => {
        const fileInput = document.getElementById("new-media-file");
        const url = "/api/narrations/" + state.chapter.narrationId + "/files";

        const xhr = new XMLHttpRequest();
        xhr.open("POST", url);
        // xhr.setRequestHeader("Content-Type", "application/json");
        xhr.addEventListener("load", function() {
            const response = JSON.parse(this.responseText);

            if (this.status >= 400) {
                alert("Could not add media file: " + response.errorMessage);
                done();
                return;
            }

            send("receiveMediaFileResponse", response, done);
        });

        const formData = new FormData();
        formData.append("file", fileInput.files[0]);
        xhr.send(formData);
    }
};
