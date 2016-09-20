const html = require("choo/html");

const fragmentView = (fragment, send) => html`
  <li><a href="/fragments/${ fragment.id }">${ fragment.id } -
  ${ fragment.title }</a>
`;

const fragmentListView = (narration, send) => html`
  <div class="fragment-list">
    <ul>
      ${ narration.fragments.map(f => fragmentView(f, send)) }
    </ul>

    <a href="/narrations/${ narration.id }/new">Create new narration fragment</a>
  </div>
`;

module.exports = fragmentListView;
