const choo = require("choo");

const editor = require("./editor");
const reducers = require("./reducers");
const effects = require("./effects");
const narrationView = require("./views/narrationView"),
      createFragmentView = require("./views/createFragmentView"),
      fragmentView = require("./views/fragmentView");

const app = choo();

app.model({
    state: {
        editor: null, // ProseMirror instance

        narrator: null,

        narration: {
            id: null,
            characters: []
        },
        fragment: {
            id: null,
            narrationId: null,
            title: null,
            audio: null,
            backgroundImage: null,
            text: null,
            participants: []
        },
        newImageUrl: null
    },
    reducers: reducers,
    effects: effects
});

app.router((route) => [
    route('/narrations/:narrationId', narrationView),
    route('/narrations/:narrationId/new', createFragmentView),
    route('/fragments/:fragmentId', fragmentView)
]);

const tree = app.start();
document.body.appendChild(tree);
