const html = require("choo/html");

module.exports = function backgroundImageSelector(chapter, images, send) {
    return html`
  <div class="image-selector">
    <label>Background image</label>
    <select value=${ chapter.backgroundImage } onchange=${ e => send("updateSelectedBackgroundImage", { value: e.target.value }) }>
      ${ images.map(i => html`
          <option ${ i === chapter.backgroundImage ? "selected" : "" }>${ i }</option>
        `) }
    </select>

    <em>Preview</em>:<br>
    <img class="tiny-image-preview" src="/static/narrations/${ chapter.narrationId }/background-images/${ chapter.backgroundImage }" />
  </div>
`;
};
