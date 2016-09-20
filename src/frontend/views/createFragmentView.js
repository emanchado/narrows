const html = require("choo/html");

const createFragmentView = (state, prev, send) => html`
  <main onload=${ () => { send("createEmptyEditor"); } }>
    <div class="editor-container">
      ${ state.editor ? state.editor.wrapper : "" }
    </div>

    <button onclick=${ () => { send("saveFragment", { narrationId: state.params.narrationId }); }}>Save</button>
  </main>
`;

module.exports = createFragmentView;
