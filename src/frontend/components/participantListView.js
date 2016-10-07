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

module.exports = (fragment, characters, send) => html`
  <aside class="participants">
    <h2>Participants</h2>
    <ul>
      ${ fragment.participants.map(p => html`
          <li><a href="/read/${ fragment.id }/${ p.token }">${ p.name }</a>
          <img onclick=${ () => send("removeParticipant", { characterId: p.id }) } src="/img/delete.png" /></li>
        `) }
    </ul>

    <h2>Other characters</h2>
    ${ (fragment.participants.length < characters.length) ? nonParticipantList(fragment.participants, characters, send) : "All participating" }
  </aside>
`;
