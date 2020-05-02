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

app.use(express.static('public'));
app.use(bodyParser.urlencoded({extended: false}));
app.use(bodyParser.json());
app.use(expressSession({
    store: new MySQLStore({}, mysql.createPool(config.db)),
    resave: false,
    saveUninitialized: false,
    secret: "b7404074-874d-11e6-855e-031b367b72bb",
    cookie: { maxAge: 7 * 24 * 60 * 60 * 1000 }
}));

// Note that this is just a "middleware"
app.get("/password-reset/:token", middlewares.getPasswordReset);

// Session endpoints
app.get("/api/session", endpoints.getSession);
app.post("/api/session", endpoints.postSession);
app.delete("/api/session", endpoints.deleteSession);

// Regular API endpoints only for logged-in users
app.get("/api/narrations/overview", middlewares.apiAuth, endpoints.getNarrationOverview);
app.get("/api/narrations", middlewares.apiAuth, endpoints.getNarrationArchive);
app.get("/api/characters", middlewares.apiAuth, endpoints.getCharacterArchive);
app.post("/api/narrations", middlewares.apiAuth, endpoints.postNarration);
app.get("/api/narrations/:narrId", middlewares.apiAuth, endpoints.getNarration);
app.put("/api/narrations/:narrId", middlewares.apiAuth, endpoints.putNarration);
app.delete("/api/narrations/:narrId", middlewares.apiAuth, endpoints.deleteNarration);
app.get("/api/narrations/:narrId/chapters", middlewares.apiAuth, endpoints.getNarrationChapters);
app.post("/api/narrations/:narrId/chapters", middlewares.apiAuth, endpoints.postNewChapter);
app.post("/api/narrations/:narrId/images", middlewares.apiAuth, endpoints.postNarrationImages);
app.post("/api/narrations/:narrId/background-images", middlewares.apiAuth, endpoints.postNarrationBackgroundImages);
app.post("/api/narrations/:narrId/audio", middlewares.apiAuth, endpoints.postNarrationAudio);
app.post("/api/narrations/:narrId/characters", middlewares.apiAuth, endpoints.postNarrationCharacters);
app.get("/api/narrations/:narrId/last-reactions", middlewares.apiAuth, endpoints.getNarrationLastReactions);
app.get("/api/narrations/:narrId/search", middlewares.apiAuth, endpoints.getNarrationChapterSearch);

app.get("/api/chapters/:chptId", middlewares.apiAuth, endpoints.getChapter);
app.put("/api/chapters/:chptId", middlewares.apiAuth, endpoints.putChapter);
app.get("/api/chapters/:chptId/interactions", middlewares.apiAuth, endpoints.getChapterInteractions);
app.post("/api/chapters/:chptId/messages", middlewares.apiAuth, endpoints.postChapterMessages);
app.get("/api/chapters/:chptId/last-reactions", middlewares.apiAuth, endpoints.getChapterLastReactions);

app.put("/api/users/:userId", middlewares.apiAuth, endpoints.putUser);
app.delete("/api/users/:userId", middlewares.apiAuth, endpoints.deleteUser);
app.get("/api/characters/by-id/:charId", middlewares.apiAuth, endpoints.getCharacterById);
app.put("/api/characters/by-id/:charId", middlewares.apiAuth, endpoints.putCharacterById);
app.delete("/api/characters/by-id/:charId", middlewares.apiAuth, endpoints.deleteCharacterById);
app.post("/api/characters/by-id/:charId/token", middlewares.apiAuth, endpoints.postCharacterByIdToken);
app.delete("/api/characters/by-id/:charId/claim", middlewares.apiAuth, endpoints.deleteCharacterByIdClaim);

// This are only for admins
app.get("/api/users", middlewares.apiAuth, endpoints.getUsers);
app.post("/api/users", middlewares.apiAuth, endpoints.postUser);

// Public endpoints, only protected by an unguessable string
app.get("/api/narrations/by-token/:narrToken", endpoints.getNarrationByToken);
app.get("/api/chapters/:chptId/:charToken", endpoints.getChapterCharacter);
app.get("/api/messages/:chptId/:charToken", endpoints.getMessagesCharacter);
app.post("/api/messages/:chptId/:charToken", endpoints.postMessageCharacter);
app.put("/api/notes/:charToken", endpoints.putNotesCharacter);
app.get("/api/characters/:charToken", endpoints.getCharacter);
app.put("/api/characters/:charToken", endpoints.putCharacter);
app.put("/api/characters/:charToken/avatar", endpoints.putCharacterAvatar);
app.get("/api/novels/:novelToken", endpoints.getNovel);
app.post("/api/verify-email/:token", endpoints.postVerifyEmail);
// This is an RSS feed (public, only protected by an unguessable string)
app.get("/feeds/:charToken", endpoints.getFeedsCharacter);
// Public API endpoints
app.post("/api/characters/by-id/:charId/claim", endpoints.postCharacterClaim);
app.post("/api/password-reset", endpoints.postPasswordReset);

// Catch-all for non-existent API paths
app.use("/api", function(req, res) {
    res.status(404).send("Not Found");
});

app.use("/static/narrations", express.static(config.files.path));

app.use(middlewares.firstTimeSetup, function(req, res) {
    res.sendFile(path.resolve(path.join(STATIC_HTML_FILES, "index.html")));
});

app.use(function(err, req, res, next) {
    res.status(500).sendFile(
        path.resolve(path.join(STATIC_HTML_FILES, "error.html"))
    );
});

app.listen(config.port, function () {
  console.log(`Narrows app listening on port ${ config.port }!`);
});
