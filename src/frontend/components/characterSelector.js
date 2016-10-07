const html = require("choo/html");

function getFromPath(obj, path) {
    return obj[path];
}

function selectedValues(selectEl) {
    return Array.prototype.filter.call(selectEl.children, optionEl => {
        return optionEl.selected;
    }).map(
        optionEl => optionEl.value
    );
}

module.exports = function characterSelector(path, characters, state, send) {
    const selectedCharacters = getFromPath(state, path) || [];

    return html`
  <div>
    ${ characters.map(char => html`
        <label>
          <input type="checkbox"
                 ${ selectedCharacters.includes(char.id) ? "checked" : "" }
                 onclick=${ () => send("toggleMentionCharacter",
                                       { path, value: char.id }) } />
          ${ char.name }
        </label>
`) }
  </div>
`;
};
