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

app.use(express.static('public'));
app.use(bodyParser.urlencoded({extended: false}));
app.use(bodyParser.json());
app.use(expressSession({
    store: new SQLiteStore({ db: config.db.path.replace(".db", ""),
                             dir: "." }),
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

app.get("/api/fragments/:fgmtId", middlewares.apiAuth, endpoints.getFragment);
app.put("/api/fragments/:fgmtId", middlewares.apiAuth, endpoints.postFragment);

app.get("/api/fragments/:fgmtId/:charToken", endpoints.getFragmentCharacter);
app.put("/api/reactions/:fgmtId/:charToken", endpoints.putReaction);

app.get("/static/narrations/:narrId/:filename", endpoints.getStaticFile);

app.listen(3000, function () {
  console.log('Example app listening on port 3000!');
});
