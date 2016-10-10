const choo = require("choo");
const html = require("choo/html");
const http = require("choo/http");

const narrowsSchema = require("./narrows-schema").schema;
const model = require("prosemirror/dist/model"),
      Node = model.Node;
const extend = require("./extend");
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
        characterToken: getCharacterTokenFromUrl(location.pathname),
        backgroundMusic: true,

        banner: null
    },
    reducers: {
        receiveFragmentData: (fragmentData, state) => {
            return extend(state, { fragment: fragmentData });
        },

        fragmentDataFailure: (info, state) => {
            return extend(state, { error: `Failed fetching fragment, status code: ${ info.statusCode }` });
        },

        markNarrationAsStarted: (data, state) => {
            return extend(state, {
                started: true,
                musicPlaying: state.backgroundMusic
            });
        },

        pageScrolled: (data, state) => {
            const blurriness = Math.min(window.scrollY / 40,
                                        MAX_BLURRINESS);

            return extend(state, { backgroundBlurriness: blurriness });
        },

        updateReactionText: (data, state) => {
            return extend(state, {
                fragment: extend(state.fragment, { reaction: data.value })
            });
        },

        toggleBackgroundMusic: (data, state) => {
            return extend(state, { backgroundMusic: !state.backgroundMusic });
        },

        toggleMusicPlaying: (data, state) => {
            return extend(state, { musicPlaying: !state.musicPlaying });
        },

        reactionSendingProblem: (data, state) => {
            return extend(
                state,
                { banner: {
                    type: "error",
                    text: "There was a problem sending your reaction!\n" +
                        "Maybe save the text somewhere just in case..."
                } }
            );
        },

        reactionSendingSuccess: (data, state) => {
            return extend(state, { banner: { type: "success",
                                             text: "Reaction registered"},
                                   reaction: "",
                                   reactionSent: true });
        }
    },
    effects: {
        getFragment: (data, state, send, done) => {
            http("/api/fragments/" + state.fragmentId + "/" + state.characterToken, (err, res, body) => {
                if (res.statusCode >= 400) {
                    send("fragmentDataFailure",
                         { statusCode: res.statusCode },
                         done);
                    return;
                }

                const response = JSON.parse(body);
                response.text = editor.importText(response.text);

                send("receiveFragmentData", response, done);
            });
        },

        startNarration: (data, state, send, done) => {
            if (state.backgroundMusic) {
                const audioEl = document.getElementById("background-music");
                setTimeout(() => {
                    audioEl.volume = 0.1;
                    audioEl.play();
                    bumpVolume(audioEl);
                }, 1000);
            }

            // First we need to make it appear on screen at all
            // (remove the "invisible" classname, which sets "display:
            // none") and then we'll remove the "transparent"
            // classname, which sets "opacity: 0". If we remove both
            // CSS properties at the same time, the opacity is not
            // animated.
            const fragmentContainer = document.getElementById("fragment-container");
            fragmentContainer.className = "transparent";

            send("markNarrationAsStarted", {}, done);
        },

        playPauseMusic: (data, state, send, done) => {
            const audioEl = document.getElementById("background-music");
            if (audioEl.paused) {
                audioEl.play();
            } else {
                audioEl.pause();
            }
            send("toggleMusicPlaying", {}, done);
        },

        sendReaction: (data, state, send, done) => {
            const url = "/api/reactions/" + state.fragmentId + "/" +
                      state.characterToken;

            if (!state.fragment || !state.fragment.reaction) {
                done();
                return;
            }

            const xhr = new XMLHttpRequest();
            xhr.open("PUT", url);
            xhr.setRequestHeader("Content-Type", "application/json");
            xhr.addEventListener("load", function() {
                const response = JSON.parse(this.responseText);
                if (this.status >= 400) {
                    send("reactionSendingProblem", {response: this}, done);
                    return;
                }

                send("reactionSendingSuccess", {}, done);
            });
            xhr.send(JSON.stringify({ text: state.fragment.reaction }));
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

const loadingView = () => html`
  <div id="spinner">Loading…</div>
`;

const loadedView = (state, send) => html`
  <div id="start-ui">
    <button onclick=${ () => send("startNarration") }>Start</button>

    <br />
    <input id="music"
           type="checkbox"
           checked="${ state.backgroundMusic ? "checked" : "false" }"
           onclick=${ () => send("toggleBackgroundMusic") } />
    <label for="music">Background music</label>
  </div>
`;

const loaderView = (state, prev, send) => html`
    <div id="loader">
      ${ state.fragment ? loadedView(state, send) : loadingView() }
    </div>
`;

const errorView = (error, send) => html`
  <div class="banner banner-error">
    ${ error }
  </div>
`;

function backgroundImageStyle(state) {
    const imageUrl = state.fragment ?
              ("/static/narrations/" + state.fragment.narrationId + "/" + state.fragment.backgroundImage) : '';
    const filter = `blur(${ state.backgroundBlurriness || 0 }px)`;

    return `background-image: url(${ imageUrl }); ` +
        `-webkit-filter: ${ filter }; ` +
        `-moz-filter: ${ filter }; ` +
        `filter: ${ filter }`;
}

const bannerView = (banner) => html`
  <div class="banner banner-${ banner.type }">
    ${ banner.text }
  </div>
`;

const fragmentView = (state, prev, send) => html`
    <div id="fragment-container" class=${ state.started ? "" : "invisible transparent" }>
      <div id="top-image" style=${ backgroundImageStyle(state) }>
        ${ state.fragment ? state.fragment.title : 'Untitled' }
      </div>
      <img id="play-icon"
           src="/img/${ state.musicPlaying ? "play" : "mute" }-small.png"
           alt="${ state.musicPlaying ? "Stop" : "Start" } music"
           onclick=${() => { send("playPauseMusic"); }} />
      <audio id="background-music"
             src="${ state.fragment ? ("/static/narrations/" + state.fragment.narrationId + "/" + state.fragment.audio) : '' }"
             loop="true"
             preload="${ state.backgroundMusic ? "auto" : "none" }"></audio>

      <div class="fragment">
        ${ state.fragment ? state.fragment.text.content.toDOM() : "" }
      </div>

      ${ state.banner ? bannerView(state.banner) : "" }

      <div class="player-reply ${ state.reactionSent ? "invisible" : "" }">
        <textarea
           placeholder="How do you react? Try to consider several possibilities…"
           rows="10"
           value=${ state.fragment && state.fragment.reaction }
           oninput=${ e => { send("updateReactionText", { value: e.target.value }); } }>${ state.fragment && state.fragment.reaction }</textarea>
        <button class="btn-default" onclick=${ () => send("sendReaction") }>Send</button>
      </div>
    </div>
`;

const mainView = (state, prev, send) => html`
  <main onload=${() => send("getFragment")}>
    ${ (!state.started && !state.error) ? loaderView(state, prev, send) : "" }
    ${ state.error ? errorView(state.error, send) : "" }

    ${ fragmentView(state, prev, send) }
  </main>
`;

app.router((route) => [
  route('/', mainView)
]);

const tree = app.start();
document.body.appendChild(tree);
