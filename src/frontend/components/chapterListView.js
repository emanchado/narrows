const html = require("choo/html");

const chapterView = (chapter, send) => html`
  <li>
    <a href="/chapters/${ chapter.id }">
      ${ chapter.title || ("Untitled #" + chapter.id) }</a>
    -
    ${ chapter.reactions.filter(r => r.text).length } /
      ${ chapter.reactions.length } reactions
    (${ chapter.numberMessages } messages)
  </li>
`;

const chapterListView = (narration, send) => html`
  <ul class="chapter-list">
    ${ narration.chapters.map(f => chapterView(f, send)) }
  </ul>
`;

module.exports = chapterListView;
