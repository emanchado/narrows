import path from "path";
import config from "config";
import express from "express";
import expressSession from "express-session";
import connectSqlite3 from "connect-sqlite3";
import bodyParser from "body-parser";

import * as endpoints from "./endpoints";
import * as middlewares from "./middlewares";

const STATIC_HTML_FILES = path.join(__dirname, "..", "html");

const app = express();
const SQLiteStore = connectSqlite3(expressSession);
const dbDirname = path.dirname(config.db.path),
      dbBasename = path.basename(config.db.path);

app.use(express.static('public'));
app.use(bodyParser.urlencoded({extended: false}));
app.use(bodyParser.json());
app.use(expressSession({
    store: new SQLiteStore({ db: dbBasename.replace(".db", ""),
                             dir: dbDirname }),
    resave: false,
    saveUninitialized: false,
    secret: "b7404074-874d-11e6-855e-031b367b72bb",
    cookie: { maxAge: 7 * 24 * 60 * 60 * 1000 }
}));

// These static file endpoints also accept POST because that's how the
// login system works
app.all("/read/:chptId/:characterId", function(req, res) {
    res.sendFile(path.resolve(path.join(STATIC_HTML_FILES, "read.html")));
});

app.all("/narrations/:narrationId", middlewares.auth, function(req, res) {
    res.sendFile(path.resolve(path.join(STATIC_HTML_FILES, "narrator.html")));
});
app.all("/narrations/:narrationId/new", middlewares.auth, function(req, res) {
    res.sendFile(path.resolve(path.join(STATIC_HTML_FILES, "narrator.html")));
});
app.all("/chapters/:chapterId", middlewares.auth, function(req, res) {
    res.sendFile(path.resolve(path.join(STATIC_HTML_FILES, "narrator.html")));
});

app.get("/api/narrations/:narrId", middlewares.apiAuth, endpoints.getNarration);
app.get("/api/narrations/:narrId/chapters", middlewares.apiAuth, endpoints.getNarrationChapters);
app.post("/api/narrations/:narrId/chapters", middlewares.apiAuth, endpoints.postNewChapter);
app.post("/api/narrations/:narrId/files", middlewares.apiAuth, endpoints.postNarrationFiles);

app.get("/api/chapters/:chptId", middlewares.apiAuth, endpoints.getChapter);
app.put("/api/chapters/:chptId", middlewares.apiAuth, endpoints.putChapter);
app.post("/api/chapters/:chptId/participants", middlewares.apiAuth, endpoints.postChapterParticipants);
app.delete("/api/chapters/:chptId/participants/:charId", middlewares.apiAuth, endpoints.deleteChapterParticipant);

app.get("/api/chapters/:chptId/:charToken", endpoints.getChapterCharacter);
app.put("/api/reactions/:chptId/:charToken", endpoints.putReactionCharacter);
app.get("/api/messages/:chptId/:charToken", endpoints.getMessagesCharacter);
app.post("/api/messages/:chptId/:charToken", endpoints.postMessageCharacter);

app.use("/static/narrations", express.static(config.files.path));

app.listen(config.port, function () {
  console.log(`Narrows app listening on port ${ config.port }!`);
});
