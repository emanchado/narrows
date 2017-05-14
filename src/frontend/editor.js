const {EditorState} = require("prosemirror-state");
const {EditorView} = require("prosemirror-view");
const {Node, DOMSerializer} = require("prosemirror-model");
const {editorSetup} = require("./setup");

function _importText(text, schema) {
    if (!text) {
        return undefined;
    }
    return Node.fromJSON(schema, text);
}

function _textToState(text, schema) {
    return EditorState.create({
        doc: _importText(text, schema),
        schema: schema,
        plugins: editorSetup({schema: schema})
    });
}

function create(initialContent, schema, place, onChangeHandler) {
    const view = new EditorView(place, {
        state: _textToState(initialContent, schema),
        images: [],
        dispatchTransaction: tr => {
            view.updateState(view.state.apply(tr));
            onChangeHandler(view);
        }
    });

    return view;
}

function updateText(editor, newText, schema) {
    editor.updateState(_textToState(newText, schema));
}

function exportText(editor) {
    return editor.state.doc.toJSON();
}

function promoteBlockImages(block) {
    if (block.type === "paragraph" &&
            block.content && block.content.length === 1 &&
            block.content[0].type === "image") {
        return block.content[0];
    }

    return block;
}

function fixBlockImages(jsonDoc) {
    if (!jsonDoc || !jsonDoc.content) {
        return jsonDoc;
    }

    jsonDoc.content = jsonDoc.content.map(promoteBlockImages);
    return jsonDoc;
}

function exportTextToDOM(text, schema) {
    const importedText = _importText(fixBlockImages(text), schema);
    const serializer = DOMSerializer.fromSchema(schema);
    return importedText ?
        serializer.serializeFragment(importedText.content) :
        document.createElement("div");
}

function updateParticipants(editorView, participants) {
    editorView.props.participants = participants;
}

module.exports.create = create;
module.exports.updateText = updateText;
module.exports.exportText = exportText;
module.exports.exportTextToDOM = exportTextToDOM;
module.exports.updateParticipants = updateParticipants;
