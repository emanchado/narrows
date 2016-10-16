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
app.all("/read/:fgmtId/:characterId", function(req, res) {
    res.sendFile(path.resolve(path.join(STATIC_HTML_FILES, "read.html")));
});

app.all("/narrations/:narrationId", middlewares.auth, function(req, res) {
    res.sendFile(path.resolve(path.join(STATIC_HTML_FILES, "narrator.html")));
});
app.all("/narrations/:narrationId/new", middlewares.auth, function(req, res) {
    res.sendFile(path.resolve(path.join(STATIC_HTML_FILES, "narrator.html")));
});
app.all("/fragments/:fragmentId", middlewares.auth, function(req, res) {
    res.sendFile(path.resolve(path.join(STATIC_HTML_FILES, "narrator.html")));
});

app.get("/api/narrations/:narrId", middlewares.apiAuth, endpoints.getNarration);
app.get("/api/narrations/:narrId/fragments", middlewares.apiAuth, endpoints.getNarrationFragments);
app.post("/api/narrations/:narrId/fragments", middlewares.apiAuth, endpoints.postNewFragment);
app.post("/api/narrations/:narrId/files", middlewares.apiAuth, endpoints.postNarrationFiles);

app.get("/api/fragments/:fgmtId", middlewares.apiAuth, endpoints.getFragment);
app.put("/api/fragments/:fgmtId", middlewares.apiAuth, endpoints.putFragment);
app.post("/api/fragments/:fgmtId/participants", middlewares.apiAuth, endpoints.postFragmentParticipants);
app.delete("/api/fragments/:fgmtId/participants/:charId", middlewares.apiAuth, endpoints.deleteFragmentParticipant);

app.get("/api/fragments/:fgmtId/:charToken", endpoints.getFragmentCharacter);
app.put("/api/reactions/:fgmtId/:charToken", endpoints.putReaction);

app.use("/static/narrations", express.static(config.files.path));

app.listen(config.port, function () {
  console.log(`Example app listening on port ${ config.port }!`);
});
