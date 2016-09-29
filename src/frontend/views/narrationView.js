const html = require("choo/html");
const fragmentListView = require("../components/fragmentListView");

const narrationDetailView = (narration, send) => html`
  <div class="narration" onload=${ () => send("getNarrationFragments", { narrationId: narration.id }) }>
    <h1>Narration ${ narration.title }</h1>

    ${ narration.fragments ? fragmentListView(narration.fragments, send) : "Loading..." }

    <a href="/narrations/${ narration.id }/new">Create new narration fragment</a>
  </div>
`;

const narrationView = (state, prev, send) => html`
  <main onload=${ () => send("getNarration", { narrationId: state.params.narrationId }) }>
    ${ state.narration ? narrationDetailView(state.narration, send) : 'Loading...' }
  </main>
`;

module.exports = narrationView;
