const html = require("choo/html");

module.exports = function audioSelector(fragment, audioFiles, send) {
    return html`
  <div class="audio-selector">
    <label>Audio</label>
    <select value=${ fragment.audio } onchange=${ e => send("updateSelectedAudio", { value: e.target.value }) }>
      ${ audioFiles.map(i => html`
          <option ${ i === fragment.audio ? "selected" : "" }>${ i }</option>
        `) }
    </select>

    <button class="btn btn-small"
            onclick=${ () => send("playPausePreview", { id: "audio-preview" }) }>Preview <span class="bigger">♫</span></button>
    <audio id="audio-preview" src="/static/narrations/${ fragment.narrationId }/audio/${ fragment.audio }"></audio>
  </div>
`;
};
