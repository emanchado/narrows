/*global app */

const editor = require("./editor");

/*
 * Ports for the reader app
 */

function bumpVolume(audioEl) {
    audioEl.volume = Math.min(1, audioEl.volume + 0.02);

    if (audioEl.volume < 1) {
        setTimeout(function() {
            bumpVolume(audioEl);
        }, 100);
    }
}

app.ports.renderChapter.subscribe(evt => {
    const elem = document.getElementById(evt.elemId);
    if (!elem) {
        return;
    }
    const importedText = editor.importText(evt.text);
    elem.innerHTML = "";
    elem.appendChild(importedText.content.toDOM());
});

app.ports.startNarration.subscribe(evt => {
    const breathHoldingTime = 700;

    // Make chapter fade-in after a short pause (breathHoldingTime
    // above)
    setTimeout(() => {
        app.ports.markNarrationAsStarted.send(breathHoldingTime);

        // Fade audio in, too
        const audioEl = document.getElementById(evt.audioElemId);
        if (!audioEl) {
            return;
        }
        audioEl.volume = 0.1;
        audioEl.play();
        bumpVolume(audioEl);
    }, breathHoldingTime);
});

app.ports.playPauseNarrationMusic.subscribe(evt => {
    const audioEl = document.getElementById(evt.audioElemId);
    if (audioEl.paused) {
        audioEl.play();
    } else {
        audioEl.pause();
    }
});

app.ports.flashElement.subscribe(elemId => {
    const el = document.getElementById(elemId);
    if (!el) {
        return;
    }
    el.style.display = "";
    setTimeout(() => {
        el.style.display = "none";
    }, 3000);
});

document.addEventListener("scroll", function(evt) {
    app.ports.pageScrollListener.send(window.scrollY);
}, false);

/*
 * Ports for the narrator app
 */
const editors = {};
app.ports.initEditor.subscribe(evt => {
    const container = document.getElementById(evt.elemId);
    editors[evt.elemId] =
        editor.create(editor.importText(evt.text), container, m => {
            app.ports.editorContentChanged.send(editor.exportText(m));
        });
});
app.ports.addImage.subscribe(evt => {
    const editorInstance = editors[evt.editor];
    if (!editorInstance) {
        return;
    }

    editor.addImage(editorInstance, evt.imageUrl);
});
app.ports.addMention.subscribe(evt => {
    const editorInstance = editors[evt.editor];
    if (!editorInstance) {
        return;
    }

    editor.addMention(editorInstance, evt.targets);
});
app.ports.playPauseAudioPreview.subscribe(audioElemId => {
    const audioEl = document.getElementById(audioElemId);
    if (!audioEl) {
        return;
    }

    if (audioEl.paused) {
        audioEl.play();
    } else {
        audioEl.pause();
    }
});
app.ports.openFileInput.subscribe(fileInputId => {
    const fileInput = document.getElementById(fileInputId);
    if (!fileInput) {
        return;
    }

    fileInput.click();
});
app.ports.uploadFile.subscribe(evt => {
    const fileInput = document.getElementById(evt.fileInputId);
    const url = "/api/narrations/" + evt.narrationId + "/files";

    const xhr = new XMLHttpRequest();
    xhr.open("POST", url);
    xhr.addEventListener("load", function() {
        const resp = JSON.parse(this.responseText);

        if (this.status < 200 || this.status >= 400) {
            app.ports.uploadFileError.send({ status: this.status,
                                             message: resp.errorMessage });
            return;
        }

        app.ports.uploadFileSuccess.send({ name: resp.name,
                                           "type'": resp.type });
    });

    const formData = new FormData();
    formData.append("file", fileInput.files[0]);
    xhr.send(formData);
});
