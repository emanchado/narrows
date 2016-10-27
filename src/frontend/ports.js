/*global app */

const editor = require("./editor");

app.ports.renderChapter.subscribe(function(evt) {
    const elem = document.getElementById(evt.elemId);
    if (!elem) {
        return;
    }
    const importedText = editor.importText(evt.text);
    elem.innerHTML = "";
    elem.appendChild(importedText.content.toDOM());
});

document.addEventListener("scroll", function(evt) {
    console.log("Sending", window.scrollY, "to the app");
    app.ports.pageScrollListener.send(window.scrollY);
}, false);
