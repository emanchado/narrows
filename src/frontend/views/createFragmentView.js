const html = require("choo/html");

const createFragmentView = (state, prev, send) => {
    const narrationId = state.params.narrationId;

    if (!state.narration) {
        send("getNarration", { narrationId });
    }

    return html`
  <main onload=${ () => { send("createEmptyEditor"); } }>
    <label>Title</label>
    <input class="fragment-title"
           type="text"
           oninput=${ e => { send("updateFragmentTitle", { value: e.target.value }); } }
           value=${ state.fragment.title || "" } />

    <label>Participants</label>
    All

    <label>Text</label>
    <div class="editor-container">
      ${ state.editorNew ? state.editorNew.wrapper : "" }
    </div>

    <button onclick=${ () => { send("saveNewFragment", { narrationId: narrationId }); }}>Save</button>
  </main>
`;
};

module.exports = createFragmentView;
