const html = require("choo/html");

const nonParticipantList = (participants, characters, send) => {
    const nonParticipants =
              characters.filter(ch => participants.every(p => p.id !== ch.id));

    return html`
  <ul>
    ${ nonParticipants.map(np => html`
        <li>${ np.name }
          <img src="/img/add.png" onclick=${ () => send("addParticipant", { character: np }) } /></li>
      `) }
  </ul>
`;
};

module.exports = (chapter, characters, send) => html`
  <div class="participants">
    <h2>Participants</h2>
    <ul>
      ${ chapter.participants.map(p => html`
          <li><a href="/read/${ chapter.id }/${ p.token }">${ p.name }</a>
          <img onclick=${ () => send("removeParticipant", { characterId: p.id }) } src="/img/delete.png" /></li>
        `) }
    </ul>

    <h2>Other characters</h2>
    ${ (chapter.participants.length < characters.length) ? nonParticipantList(chapter.participants, characters, send) : html`<em>No other characters.</em>` }
  </div>
`;
