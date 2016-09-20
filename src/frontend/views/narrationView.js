const html = require("choo/html");
const fragmentListView = require("../components/fragmentListView");

const narrationView = (state, prev, send) => html`
  <main onload=${ () => send("getNarration", { narrationId: state.params.narrationId }) }>
    ${ state.narration ? fragmentListView(state.narration, send) : "No narration" }
  </main>
`;

module.exports = narrationView;
