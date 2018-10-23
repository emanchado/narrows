/*global app */

const editor = require("./editor");
const schemas = require("./narrows-schemas");

const DEVICE_SETTINGS_TTL = 60 * 60 * 24 * 180;

/*
 * Ports for the reader app
 */

function readCookie(name, defaultValue) {
    var nameEQ = name + "=";
    var ca = document.cookie.split(";");
    for (var i = 0; i < ca.length; i++) {
        var c = ca[i];
        while (c.charAt(0) == " ") c = c.substring(1, c.length);
        if (c.indexOf(nameEQ) == 0)
            return c.substring(nameEQ.length, c.length);
    }
    return defaultValue;
}

function bumpVolume(audioEl) {
    audioEl.volume = Math.min(1, audioEl.volume + 0.02);

    if (audioEl.volume < 1) {
        setTimeout(function() {
            bumpVolume(audioEl);
        }, 100);
    }
}

app.ports.renderText.subscribe(evt => {
    // Make sure the DOM elements are already rendered
    requestAnimationFrame(() => {
        const elem = document.getElementById(evt.elemId);
        if (!elem) {
            console.error("Cannot render text into " + evt.elemId +
                          ", element does not exist (yet?)");
            return;
        }
        elem.innerHTML = "";
        elem.appendChild(editor.exportTextToDOM(evt.text,
                                                schemas[evt.proseMirrorType]));
    });
});

app.ports.startNarration.subscribe(evt => {
    // Fade audio in right away: we cannot wait for this because
    // Blink-based mobile browsers don't allow starting audio without
    // direct user interaction, and using setTimeout makes the browser
    // think that it didn't start with a button click.
    if (evt.audioElemId) {
        const audioEl = document.getElementById(evt.audioElemId);
        if (audioEl) {
            audioEl.volume = 0.1;
            audioEl.play();
            bumpVolume(audioEl);
        } else {
            console.warn("Audio element", evt.audioElemId, "not found");
        }
    }

    // Make chapter text fade-in after a short pause
    const breathHoldingTime = 700;
    setTimeout(() => {
        app.ports.markNarrationAsStarted.send(breathHoldingTime);
    }, breathHoldingTime);
});

app.ports.playPauseNarrationMusic.subscribe(evt => {
    const audioEl = document.getElementById(evt.audioElemId);
    if (!audioEl) {
        console.warn("Audio element", evt.audioElemId, "not found");
        return;
    }

    if (audioEl.paused) {
        audioEl.play();
    } else {
        audioEl.pause();
    }
});

app.ports.playNarrationMusic.subscribe(evt => {
    const audioEl = document.getElementById(evt.audioElemId);
    if (!audioEl) {
        console.warn("Audio element", evt.audioElemId, "not found");
        return;
    }

    if (audioEl.paused) {
        audioEl.play();
    }
});

app.ports.pauseNarrationMusic.subscribe(evt => {
    const audioEl = document.getElementById(evt.audioElemId);
    if (!audioEl) {
        console.warn("Audio element", evt.audioElemId, "not found");
        return;
    }

    if (!audioEl.paused) {
        audioEl.pause();
    }
});

app.ports.flashElement.subscribe(elemId => {
    const el = document.getElementById(elemId);
    if (!el) {
        console.error(
            "Element", elemId, "doesn't exist (yet?), cannot flash it"
        );
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
const editorViews = {};
app.ports.initEditor.subscribe(evt => {
    requestAnimationFrame(() => {
        const container = document.getElementById(evt.elemId);
        const schema = schemas[evt.editorType];

        // Avoid memory leaks: if there was an editor with the same name
        // from before, remove it.
        if (editorViews.hasOwnProperty(evt.elemId)) {
            const editorEl = editorViews[evt.elemId];

            while (container.firstChild) {
                container.removeChild(container.firstChild);
            }
            container.appendChild(editorEl.dom.parentNode);

            editor.updateText(editorEl, evt.text, schema);
        } else {
            editorViews[evt.elemId] =
                editor.create(evt.text, schema, container, view => {
                    const port = app.ports[evt.updatePortName];
                    if (port) {
                        port.send(editor.exportText(view));
                    } else {
                        console.error("Cannot find editor update port '" +
                                      evt.updatePortName + "'");
                    }
                });
        }
        editorViews[evt.elemId].props.narrationId = evt.narrationId;
        editorViews[evt.elemId].props.images = evt.narrationImages;
        editorViews[evt.elemId].props.participants = evt.chapterParticipants;
    });
});
app.ports.updateParticipants.subscribe(evt => {
    const editorInstance = editorViews[evt.editor];
    if (!editorInstance) {
        console.error(
            "Cannot update participants in " + evt.editor +
                " as it doesn't exist (yet?)"
        );
        return;
    }

    editor.updateParticipants(editorInstance, evt.participantList);
});
app.ports.playPauseAudioPreview.subscribe(audioElemId => {
    const audioEl = document.getElementById(audioElemId);
    if (!audioEl) {
        console.error("Cannot play audio in non-existent element", audioElemId);
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
        console.error("Cannot open non-existent element", fileInputId);
        return;
    }

    fileInput.click();
});
app.ports.uploadFile.subscribe(evt => {
    const fileInput = document.getElementById(evt.fileInputId);
    const url = "/api/narrations/" + evt.narrationId + "/" + evt.type_;

    const xhr = new XMLHttpRequest();
    xhr.open("POST", url);
    xhr.addEventListener("load", function() {
        const resp = JSON.parse(this.responseText);

        if (this.status < 200 || this.status >= 400) {
            const errorPortName = `${evt.portType}UploadFileError`;
            app.ports[errorPortName].send({ status: this.status,
                                            message: resp.errorMessage });
            return;
        }

        const successPortName = `${evt.portType}UploadFileSuccess`;
        app.ports[successPortName].send({ name: resp.name,
                                          type_: resp.type });
    });

    const formData = new FormData();
    formData.append("file", fileInput.files[0]);
    xhr.send(formData);
});

app.ports.scrollTo.subscribe(evt => {
    window.scrollTo(0, evt);
});

app.ports.readAvatarAsUrl.subscribe(evt => {
    const file = document.getElementById(evt.fileInputId).files[0];
    if (!file) {
        return;
    }

    const reader = new FileReader();
    reader.addEventListener("load", function () {
        app.ports[`${evt.type_}ReceiveAvatarAsUrl`].send(reader.result);
    }, false);

    reader.readAsDataURL(file);
});
app.ports.uploadAvatar.subscribe(evt => {
    const fileInput = document.getElementById(evt.fileInputId);
    const url = "/api/characters/" + evt.characterToken + "/avatar";

    const xhr = new XMLHttpRequest();
    xhr.open("PUT", url);
    xhr.addEventListener("load", function() {
        const resp = JSON.parse(this.responseText);

        if (this.status < 200 || this.status >= 400) {
            app.ports[`${evt.type_}UserUploadAvatarError`].send({
                status: this.status,
                message: resp.errorMessage
            });
            return;
        }

        // Fool the browser into thinking it's a new image
        const cheekyAvatarUrl = resp.avatar + "?" + (new Date()).getTime();
        app.ports[`${evt.type_}UserUploadAvatarSuccess`].send(cheekyAvatarUrl);
    });

    const formData = new FormData();
    formData.append("avatar", fileInput.files[0]);
    xhr.send(formData);
});

app.ports.readDeviceSettings.subscribe(receivingPortName => {
    const settings = {
        backgroundMusic: !!(readCookie("backgroundMusic", true))
    };

    app.ports[receivingPortName].send(settings);
});

app.ports.setDeviceSetting.subscribe(evt => {
    document.cookie = `${evt.name}=${evt.value};path=/;max-age=${DEVICE_SETTINGS_TTL}`;
});
