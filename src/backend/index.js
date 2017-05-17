import path from "path";
import config from "config";
import express from "express";
import expressSession from "express-session";
import mysql from "mysql";
import mysqlSession from "express-mysql-session";
import bodyParser from "body-parser";

import * as endpoints from "./endpoints";
import * as middlewares from "./middlewares";

const STATIC_HTML_FILES = path.join(__dirname, "..", "html");

const app = express();
const MySQLStore = mysqlSession(expressSession);
const dbDirname = path.dirname(config.db.path),
      dbBasename = path.basename(config.db.path);

app.use(express.static('public'));
app.use(bodyParser.urlencoded({extended: false}));
app.use(bodyParser.json());
app.use(expressSession({
    store: new MySQLStore({}, mysql.createConnection(config.db)),
    resave: false,
    saveUninitialized: false,
    secret: "b7404074-874d-11e6-855e-031b367b72bb",
    cookie: { maxAge: 7 * 24 * 60 * 60 * 1000 }
}));

// These static file endpoints also accept POST because that's how the
// login system works
app.all("/read/:chptId/:characterId", function(req, res) {
    res.sendFile(path.resolve(path.join(STATIC_HTML_FILES, "index.html")));
});
app.all("/characters/:characterId", function(req, res) {
    res.sendFile(path.resolve(path.join(STATIC_HTML_FILES, "index.html")));
});
app.get("/feeds/:charToken", endpoints.getFeedsCharacter);

app.get("/api/session", endpoints.getSession);
app.post("/api/session", endpoints.postSession);

app.get("/api/narrations/overview", middlewares.apiAuth, endpoints.getNarrationOverview);
app.post("/api/narrations", middlewares.apiAuth, endpoints.postNarration);
app.get("/api/narrations/:narrId", middlewares.apiAuth, endpoints.getNarration);
app.put("/api/narrations/:narrId", middlewares.apiAuth, endpoints.putNarration);
app.get("/api/narrations/:narrId/chapters", middlewares.apiAuth, endpoints.getNarrationChapters);
app.post("/api/narrations/:narrId/chapters", middlewares.apiAuth, endpoints.postNewChapter);
app.post("/api/narrations/:narrId/files", middlewares.apiAuth, endpoints.postNarrationFiles);
app.post("/api/narrations/:narrId/images", middlewares.apiAuth, endpoints.postNarrationImages);
app.post("/api/narrations/:narrId/characters", middlewares.apiAuth, endpoints.postNarrationCharacters);
app.get("/api/narrations/:narrId/last-reactions", middlewares.apiAuth, endpoints.getNarrationLastReactions);
app.get("/api/narrations/:narrId/novels", middlewares.apiAuth, endpoints.getNovels);
app.post("/api/characters/:charId/novels", middlewares.apiAuth, endpoints.postCharacterNovel);

app.get("/api/chapters/:chptId", middlewares.apiAuth, endpoints.getChapter);
app.put("/api/chapters/:chptId", middlewares.apiAuth, endpoints.putChapter);
app.get("/api/chapters/:chptId/interactions", middlewares.apiAuth, endpoints.getChapterInteractions);
app.post("/api/chapters/:chptId/messages", middlewares.apiAuth, endpoints.postChapterMessages);
app.get("/api/chapters/:chptId/last-reactions", middlewares.apiAuth, endpoints.getChapterLastReactions);

// These endpoints are only for admins!
app.get("/api/users", middlewares.apiAdminAuth, endpoints.getUsers);
app.post("/api/users", middlewares.apiAdminAuth, endpoints.postUser);
app.put("/api/users/:userId", middlewares.apiAdminAuth, endpoints.putUser);

// Public endpoints, only protected by an unguessable string
app.get("/api/chapters/:chptId/:charToken", endpoints.getChapterCharacter);
app.put("/api/reactions/:chptId/:charToken", endpoints.putReactionCharacter);
app.get("/api/messages/:chptId/:charToken", endpoints.getMessagesCharacter);
app.post("/api/messages/:chptId/:charToken", endpoints.postMessageCharacter);
app.put("/api/notes/:charToken", endpoints.putNotesCharacter);
app.get("/api/characters/:charToken", endpoints.getCharacter);
app.put("/api/characters/:charToken", endpoints.putCharacter);
app.put("/api/characters/:charToken/avatar", endpoints.putCharacterAvatar);
app.get("/api/novels/:novelToken", endpoints.getNovel);

app.use("/static/narrations", express.static(config.files.path));

app.use(middlewares.firstTimeSetup, function(req, res) {
    res.sendFile(path.resolve(path.join(STATIC_HTML_FILES, "index.html")));
});

app.listen(config.port, function () {
  console.log(`Narrows app listening on port ${ config.port }!`);
});
