const html = require("choo/html");

const fragmentView = (fragment, send) => html`
  <li>
    <a href="/fragments/${ fragment.id }">
      ${ fragment.title || ("Untitled #" + fragment.id) }
    </a>
  </li>
`;

const fragmentListView = (narration, send) => html`
  <ul class="fragment-list">
    ${ narration.fragments.map(f => fragmentView(f, send)) }
  </ul>
`;

module.exports = fragmentListView;
