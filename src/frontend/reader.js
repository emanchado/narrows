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

function getChapterIdFromUrl(urlPath) {
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
        chapterId: getChapterIdFromUrl(location.pathname),
        chapter: null,
        characterToken: getCharacterTokenFromUrl(location.pathname),
        backgroundMusic: true,

        banner: null
    },
    reducers: {
        receiveChapterData: (chapterData, state) => {
            return extend(state, { chapter: chapterData });
        },

        chapterDataFailure: (info, state) => {
            return extend(state, { error: `Failed fetching chapter, status code: ${ info.statusCode }` });
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
                chapter: extend(state.chapter, { reaction: data.value })
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
        getChapter: (data, state, send, done) => {
            http("/api/chapters/" + state.chapterId + "/" + state.characterToken, (err, res, body) => {
                if (res.statusCode >= 400) {
                    send("chapterDataFailure",
                         { statusCode: res.statusCode },
                         done);
                    return;
                }

                const response = JSON.parse(body);
                response.text = editor.importText(response.text);

                send("receiveChapterData", response, done);
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
            const chapterContainer = document.getElementById("chapter-container");
            chapterContainer.className = "transparent";
            setTimeout(() => send("markNarrationAsStarted", {}, done),
                       50);
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
            const url = "/api/reactions/" + state.chapterId + "/" +
                      state.characterToken;

            if (!state.chapter || !state.chapter.reaction) {
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
            xhr.send(JSON.stringify({ text: state.chapter.reaction }));
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
      ${ state.chapter ? loadedView(state, send) : loadingView() }
    </div>
`;

const errorView = (error, send) => html`
  <div class="banner banner-error">
    ${ error }
  </div>
`;

function backgroundImageStyle(state) {
    const imageUrl = state.chapter ?
              ("/static/narrations/" + state.chapter.narrationId + "/background-images/" + state.chapter.backgroundImage) : '';
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

const chapterView = (state, prev, send) => html`
    <div id="chapter-container" class=${ state.started ? "" : "invisible transparent" }>
      <div id="top-image" style=${ backgroundImageStyle(state) }>
        ${ state.chapter ? state.chapter.title : 'Untitled' }
      </div>
      <img id="play-icon"
           src="/img/${ state.musicPlaying ? "play" : "mute" }-small.png"
           alt="${ state.musicPlaying ? "Stop" : "Start" } music"
           onclick=${() => { send("playPauseMusic"); }} />
      <audio id="background-music"
             src="${ state.chapter ? ("/static/narrations/" + state.chapter.narrationId + "/audio/" + state.chapter.audio) : '' }"
             loop="true"
             preload="${ state.backgroundMusic ? "auto" : "none" }"></audio>

      <div class="chapter">
        ${ state.chapter ? state.chapter.text.content.toDOM() : "" }
      </div>

      ${ state.banner ? bannerView(state.banner) : "" }

      <div class="player-reply ${ state.reactionSent ? "invisible" : "" }">
        <textarea
           placeholder="How do you react? Try to consider several possibilities…"
           rows="10"
           value=${ state.chapter && state.chapter.reaction }
           oninput=${ e => { send("updateReactionText", { value: e.target.value }); } }>${ state.chapter && state.chapter.reaction }</textarea>
        <button class="btn-default" onclick=${ () => send("sendReaction") }>Send</button>
      </div>
    </div>
`;

const mainView = (state, prev, send) => html`
  <main onload=${() => send("getChapter")}>
    <div>
      ${ (!state.started && !state.error) ? loaderView(state, prev, send) : "" }
    </div>
    ${ state.error ? errorView(state.error, send) : "" }

    ${ chapterView(state, prev, send) }
  </main>
`;

app.router((route) => [
  route('/', mainView)
]);

const tree = app.start();
document.body.appendChild(tree);
