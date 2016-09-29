const html = require("choo/html");
const fragmentListView = require("../components/fragmentListView");

const narrationView = (state, prev, send) => html`
  <main onload=${ () => send("getNarration", { narrationId: state.params.narrationId }) }>
    <h1>Narration ${ state.params.narrationId }</h1>

    ${ state.narration ? fragmentListView(state.narration, send) : "No narration" }

    <a href="/narrations/${ state.params.narrationId }/new">Create new narration fragment</a>
  </main>
`;

module.exports = narrationView;
