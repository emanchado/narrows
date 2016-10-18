const html = require("choo/html");
const chapterListView = require("../components/chapterListView");

const narrationDetailView = (narration, send) => html`
  <div class="narration" onload=${ () => send("getNarrationChapters", { narrationId: narration.id }) }>
    <h1>Narration ${ narration.title }</h1>

    ${ narration.chapters ? chapterListView(narration.chapters, send) : "Loading..." }

    <a href="/narrations/${ narration.id }/new">Create new narration chapter</a>
  </div>
`;

const narrationView = (state, prev, send) => html`
  <main onload=${ () => send("getNarration", { narrationId: state.params.narrationId }) }>
    ${ state.narration && state.narration.id ? narrationDetailView(state.narration, send) : 'Loading...' }
  </main>
`;

module.exports = narrationView;
