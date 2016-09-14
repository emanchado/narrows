const choo = require("choo");
const html = require("choo/html");
const http = require("choo/http");

const narrowsSchema = require("./narrows-schema");
const model = require("prosemirror/dist/model"),
      Node = model.Node;
const extend = require("./extend");

const app = choo();

function bumpVolume(audioEl) {
    audioEl.volume = Math.min(1, audioEl.volume + 0.02);

    if (audioEl.volume < 1) {
        setTimeout(function() {
            bumpVolume(audioEl);
        }, 100);
    }
}

app.model({
    state: { fragment: null },
    reducers: {
        receiveFragmentData: (fragmentData, state) => {
            return extend(state, { fragment: fragmentData });
        },

        markNarrationAsStarted: (data, state) => {
            return extend(state, { started: true });
        }
    },
    effects: {
        getFragment: (data, state, send, done) => {
            http("/api/fragments/1/atana", (err, res, body) => {
                const response = JSON.parse(body);
                const node = Node.fromJSON(narrowsSchema, response.text);

                send("receiveFragmentData",
                     {title: response.title,
                      text: node,
                      audio: response.audio,
                      backgroundImage: response.backgroundImage},
                     done);
            });
        },

        startNarration: (data, state, send, done) => {
            const fragmentEl = document.getElementById("fragment-container");
            // This is BAD. There's a race condition here!
            setTimeout(() => {
                fragmentEl.style.display = "block";
                setTimeout(() => { fragmentEl.style.opacity = 1; }, 100);
            }, 100);

            const audioEl = document.getElementById("background-music");
            audioEl.volume = 0;
            audioEl.play();
            bumpVolume(audioEl);
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
        }
    }
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

const fragmentView = (state, prev, send) => html`
    <div id="fragment-container">
      <div id="top-image"
           style="background-image: url(${state.fragment ? state.fragment.backgroundImage : ''})">
        ${state.fragment ? state.fragment.title : 'Untitled'}
      </div>
      <img id="play-icon"
           src="img/play-small.png"
           alt="Stop music"
           onclick=${() => { send("playPauseMusic"); }} />
      <audio id="background-music"
             src="${state.fragment ? state.fragment.audio : ''}"
             loop="true"
             preload="auto"></audio>

      <div class="fragment">
        ${state.fragment ? state.fragment.text.content.toDOM() : ""}
      </div>

      <div class="player-reply">
        <textarea
           placeholder="How do you react? Try to consider several possibilities…"
           cols="80"
           rows="10"></textarea>
        <button>Send</button>
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
