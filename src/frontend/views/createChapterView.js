const html = require("choo/html");

const createChapterView = (state, prev, send) => {
    const narrationId = state.params.narrationId;

    if (!state.narration) {
        send("getNarration", { narrationId });
    }

    return html`
  <main onload=${ () => { send("createEmptyEditor"); } }>
    <label>Title</label>
    <input class="chapter-title"
           type="text"
           oninput=${ e => { send("updateChapterTitle", { value: e.target.value }); } }
           value=${ state.chapter.title || "" } />

    <label>Participants</label>
    All

    <label>Text</label>
    <div class="editor-container">
      ${ state.editorNew ? state.editorNew.wrapper : "" }
    </div>

    <button onclick=${ () => { send("saveNewChapter", { narrationId: narrationId }); }}>Save</button>
  </main>
`;
};

module.exports = createChapterView;
