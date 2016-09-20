import path from "path";
import express from "express";
import bodyParser from "body-parser";

import * as endpoints from "./endpoints";

const STATIC_HTML_FILES = path.join(__dirname, "..", "public");

const app = express();

app.use(express.static('public'));
app.use(bodyParser.urlencoded({extended: false}));
app.use(bodyParser.json());

app.get("/read/:fgmtId/:characterId", function(req, res) {
    res.sendFile(path.resolve(path.join(STATIC_HTML_FILES, "read.html")));
});

app.get("/narrations/:narrationId", function(req, res) {
    res.sendFile(path.resolve(path.join(STATIC_HTML_FILES, "narrator.html")));
});
app.get("/narrations/:narrationId/new", function(req, res) {
    res.sendFile(path.resolve(path.join(STATIC_HTML_FILES, "narrator.html")));
});
app.get("/fragments/:fragmentId", function(req, res) {
    res.sendFile(path.resolve(path.join(STATIC_HTML_FILES, "narrator.html")));
});

app.get("/api/narrations/:narrId", endpoints.getNarration);

app.get("/api/fragments/:fgmtId", endpoints.getFragment);
app.post("/api/fragments/:fgmtId", endpoints.postFragment);
app.post("/api/narrations/:narrId/fragments", endpoints.postNewFragment);

app.get("/api/fragments/:fgmtId/:charToken", endpoints.getFragmentCharacter);
app.post("/api/reactions/:fgmtId/:charToken", endpoints.postReaction);

app.get("/static/narrations/:narrId/:filename", endpoints.getStaticFile);

app.listen(3000, function () {
  console.log('Example app listening on port 3000!');
});
