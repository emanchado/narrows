const choo = require("choo");
const html = require("choo/html");
const http = require("choo/http");

const narrowsSchema = require("./narrows-schema").schema;
const model = require("prosemirror/dist/model"),
      Node = model.Node;
const extend = require("./extend");
const fullscreen = require("./fullscreen");
const editor = require("./editor");

const MAX_BLURRINESS = 10;

const app = choo();

function getFragmentIdFromUrl(urlPath) {
    return urlPath.
        replace("/read/", "").
        replace(new RegExp("/.*"), "");
}
function getCharacterTokenFromUrl(urlPath) {
    return urlPath.
        replace(new RegExp("/$"), "").
        replace(new RegExp(".*/"), "");
}

function bumpVolume(audioEl) {
    audioEl.volume = Math.min(1, audioEl.volume + 0.02);

    if (audioEl.volume < 1) {
        setTimeout(function() {
            bumpVolume(audioEl);
        }, 100);
    }
}

app.model({
    state: {
        fragmentId: getFragmentIdFromUrl(location.pathname),
        fragment: null,
        characterToken: getCharacterTokenFromUrl(location.pathname)
    },
    reducers: {
        receiveFragmentData: (fragmentData, state) => {
            return extend(state, { fragment: fragmentData });
        },

        markNarrationAsStarted: (data, state) => {
            return extend(state, { started: true });
        },

        pageScrolled: (data, state) => {
            const blurriness = Math.min(window.scrollY / 40,
                                        MAX_BLURRINESS);

            return extend(state, { backgroundBlurriness: blurriness });
        },

        updateReactionText: (data, state) => {
            return extend(state, { reaction: data.value });
        }
    },
    effects: {
        getFragment: (data, state, send, done) => {
            http("/api/fragments/" + state.fragmentId + "/" + state.characterToken, (err, res, body) => {
                const response = JSON.parse(body);

                send("receiveFragmentData",
                     {title: response.title,
                      text: editor.importText(response.text),
                      audio: response.audio,
                      backgroundImage: response.backgroundImage},
                     done);
            });
        },

        startNarration: (data, state, send, done) => {
            const audioEl = document.getElementById("background-music");
            audioEl.volume = 0;
            audioEl.play();
            bumpVolume(audioEl);

            // fullscreen.enterFullscreen();

            send("markNarrationAsStarted", {}, done);
        },

        playPauseMusic: (data, state, send, done) => {
            const audioEl = document.getElementById("background-music");
            if (audioEl.paused) {
                audioEl.play();
            } else {
                audioEl.pause();
            }
            done();
        },

        sendReaction: (data, state, send, done) => {
            const url = "/api/reactions/" + state.fragmentId + "/" +
                      state.characterToken;

            const xhr = new XMLHttpRequest();
            xhr.open("POST", url);
            xhr.setRequestHeader("Content-Type", "application/json");
            xhr.addEventListener("load", function() {
                const response = JSON.parse(this.responseText);
                if (this.status >= 400) {
                }
            });
            xhr.send(JSON.stringify({ text: state.reaction }));
        }
    },

    subscriptions: [
        (send, done) => {
            document.addEventListener("scroll", function(evt) {
                send("pageScrolled", window.scrollY, done);
            }, false);
        }
    ]
});

const loaderView = (state, prev, send) => html`
    <div id="loader">
      <div id="spinner">
        ${state.fragment ? "" : "Loading…"}
      </div>

      <div id="start-ui">
        <button onclick=${() => send("startNarration")}>Start</button>
      </div>
    </div>
`;

function backgroundImageStyle(state) {
    const imageUrl = state.fragment ?
              ("/static/narrations/3/" + state.fragment.backgroundImage) : '';
    const filter = `blur(${ state.backgroundBlurriness || 0 }px)`;

    return `background-image: url(${ imageUrl }); ` +
        `-webkit-filter: ${ filter }; ` +
        `-moz-filter: ${ filter }; ` +
        `filter: ${ filter }`;
}

const fragmentView = (state, prev, send) => html`
    <div id="fragment-container" style=${ state.started ? "display: block; opacity: 1" : "" }>
      <div id="top-image" style=${ backgroundImageStyle(state) }>
        ${ state.fragment ? state.fragment.title : 'Untitled' }
      </div>
      <img id="play-icon"
           src="/img/play-small.png"
           alt="Stop music"
           onclick=${() => { send("playPauseMusic"); }} />
      <audio id="background-music"
             src="${state.fragment ? ("/static/narrations/3/" + state.fragment.audio) : ''}"
             loop="true"
             preload="auto"></audio>

      <div class="fragment">
        ${state.fragment ? state.fragment.text.content.toDOM() : ""}
      </div>

      <div class="player-reply">
        <textarea
           placeholder="How do you react? Try to consider several possibilities…"
           cols="80"
           rows="10"
           oninput=${ e => { send("updateReactionText", { value: e.target.value }); } }>${ state.reaction }</textarea>
        <button onclick=${ () => send("sendReaction") }>Send</button>
      </div>
    </div>
`;

const mainView = (state, prev, send) => html`
  <main onload=${() => send("getFragment")}>
    ${state.started ? "" : loaderView(state, prev, send)}

    ${fragmentView(state, prev, send)}
  </main>
`;

app.router((route) => [
  route('/', mainView)
]);

const tree = app.start();
document.body.appendChild(tree);
