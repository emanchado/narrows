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

const loadedChapterView = (state, send) => html`
  <div>
    <h1>Chapter</h1>

    <nav>
      <a href="/narrations/${ state.chapter.narrationId }">Narration</a> ⇢
        Chapter ${ state.chapter.id }
    </nav>

    <main class="page-aside">
      <section>
        <input class="chapter-title"
               type="text"
               placeholder="Title"
               oninput=${ e => { send("updateChapterTitle", { value: e.target.value }); } }
               value=${ state.chapter.title || "" } />

        <div class="editor-container">
          ${ state.editor.wrapper }
        </div>

        ${ addImageView(state, send) }

        ${ markForCharacter(state.chapter.participants, state, send) }

        <div class="btn-row">
          <button class="btn" onclick=${ () => { send("saveChapter", { chapterId: state.params.chapterId }); }}>Save</button>
          <button class="btn btn-default" onclick=${ () => { send("publishChapter", { chapterId: state.params.chapterId }); }}>Publish</button>
        </div>
      </section>

      <aside>
        ${ participantListView(state.chapter, state.narration.characters, send) }

        <h2>Media</h2>
        ${ backgroundImageSelector(state.chapter, state.narration.files.backgroundImages, send) }

        ${ audioSelector(state.chapter, state.narration.files.audio, send) }

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

const loadingChapterView = () => html `
  <div>
    Loading…
  </div>
`;

const chapterView = (state, prev, send) => {
    const chapterId = parseInt(state.params.chapterId, 10);

    if (state.chapter.id !== chapterId) {
        send("getChapter", { chapterId: state.params.chapterId });
        return loadingChapterView(state, send);
    }

    if (state.narration.id !== state.chapter.narrationId) {
        send("getNarration", { narrationId: state.chapter.narrationId });
        return loadingChapterView(state, send);
    }

    return loadedChapterView(state, send);
};

module.exports = chapterView;
