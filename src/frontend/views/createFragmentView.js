const html = require("choo/html");

const createFragmentView = (state, prev, send) => html`
  <main onload=${ () => { send("createEmptyEditor"); } }>
    <label>Title:</label>
    <br />
    <input class="fragment-title"
           type="text"
           oninput=${ e => { send("updateFragmentTitle", { value: e.target.value }); } }
           value=${ state.fragment.title || "" } />

    <div class="editor-container">
      ${ state.editorNew ? state.editorNew.wrapper : "" }
    </div>

    <button onclick=${ () => { send("saveNewFragment", { narrationId: state.params.narrationId }); }}>Save</button>
  </main>
`;

module.exports = createFragmentView;
