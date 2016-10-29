/*global app */

const editor = require("./editor");

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

document.addEventListener("scroll", function(evt) {
    app.ports.pageScrollListener.send(window.scrollY);
}, false);
