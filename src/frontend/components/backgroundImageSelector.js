const html = require("choo/html");

module.exports = function backgroundImageSelector(fragment, images, send) {
    return html`
  <div class="image-selector">
    <label>Background image</label>
    <select value=${ fragment.backgroundImage } onchange=${ e => send("updateSelectedBackgroundImage", { value: e.target.value }) }>
      ${ images.map(i => html`
          <option ${ i === fragment.backgroundImage ? "selected" : "" }>${ i }</option>
        `) }
    </select>

    <em>Preview</em>:<br>
    <img class="tiny-image-preview" src="/static/narrations/${ fragment.narrationId }/background-images/${ fragment.backgroundImage }" />
  </div>
`;
};
