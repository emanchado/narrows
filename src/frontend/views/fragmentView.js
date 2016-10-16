const html = require("choo/html");

const extend = require("../extend");

const characterSelector = require("../components/characterSelector");
const participantListView = require("../components/participantListView");
const backgroundImageSelector = require("../components/backgroundImageSelector");
const audioSelector = require("../components/audioSelector");

const addImageView = (state, send) => html`
  <div class="add-image">
    <input type="text"
           oninput=${ e => { send("updateNewImageUrl", { value: e.target.value }); } }
           value=${ state.newImageUrl || "" } />
    <button onclick=${ () => { send("addImage", { src: state.newImageUrl }); } }>Add Image</button>
  </div>
`;

const markForCharacter = (participants, state, send) => html`
  <div>
    Mark text for ${ characterSelector("mentionCharacters", participants, state, send) }
    <button onclick=${ () => send("markTextForCharacter", { characters: [{id: 1, name: "Mildred Mayfield"}] }) }>Mark</button>
  </div>
`;

const loadedFragmentView = (state, send) => html`
  <div>
    <h1>Fragment</h1>

    <nav>
      <a href="/narrations/${ state.fragment.narrationId }">Narration</a> ⇢
        Fragment ${ state.fragment.id }
    </nav>

    <main class="page-aside">
      <section>
        <input class="fragment-title"
               type="text"
               placeholder="Title"
               oninput=${ e => { send("updateFragmentTitle", { value: e.target.value }); } }
               value=${ state.fragment.title || "" } />

        <div class="editor-container">
          ${ state.editor.wrapper }
        </div>

        ${ addImageView(state, send) }

        ${ markForCharacter(state.fragment.participants, state, send) }

        <div class="btn-row">
          <button class="btn" onclick=${ () => { send("saveFragment", { fragmentId: state.params.fragmentId }); }}>Save</button>
          <button class="btn btn-default" onclick=${ () => { send("publishFragment", { fragmentId: state.params.fragmentId }); }}>Publish</button>
        </div>
      </section>

      <aside>
        ${ participantListView(state.fragment, state.narration.characters, send) }

        <h2>Media</h2>
        ${ backgroundImageSelector(state.fragment, state.narration.files.backgroundImages, send) }

        ${ audioSelector(state.fragment, state.narration.files.audio, send) }

        <button class="btn btn-small btn-default"
                onclick=${ () => send("chooseMediaFile") }>Add files</button>
        <input type="file"
               style="display: none"
               id="new-media-file"
               name="file"
               onchange=${ () => send("addMediaFile") } />
      </aside>
    </main>
  </div>
`;

const loadingFragmentView = () => html `
  <div>
    Loading…
  </div>
`;

const fragmentView = (state, prev, send) => {
    const fragmentId = parseInt(state.params.fragmentId, 10);

    if (state.fragment.id !== fragmentId) {
        send("getFragment", { fragmentId: state.params.fragmentId });
        return loadingFragmentView(state, send);
    }

    if (state.narration.id !== state.fragment.narrationId) {
        send("getNarration", { narrationId: state.fragment.narrationId });
        return loadingFragmentView(state, send);
    }

    return loadedFragmentView(state, send);
};

module.exports = fragmentView;
