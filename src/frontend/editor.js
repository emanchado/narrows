const {EditorState} = require("prosemirror-state");
const {MenuBarEditorView} = require("prosemirror-menu");
const {Node, DOMSerializer} = require("prosemirror-model");
const {schema: narrowsSchema} = require("./narrows-schema");
const {editorSetup} = require("./setup");

function textToState(text) {
    return EditorState.create({
        doc: importText(text),
        schema: narrowsSchema,
        plugins: editorSetup({schema: narrowsSchema})
    });
}

function create(initialContent, place, onChangeHandler) {
    const view = new MenuBarEditorView(place, {
        state: textToState(initialContent),
        images: [],
        dispatchTransaction: tr => {
            view.updateState(view.editor.state.apply(tr));
            onChangeHandler(view);
        }
    });

    return view;
}

function updateText(editor, newText) {
    editor.updateState(textToState(newText));
}

function importText(text) {
    if (!text) {
        return undefined;
    }
    return Node.fromJSON(narrowsSchema, text);
}

function exportText(editor) {
    return editor.state.doc.toJSON();
}

function exportTextToDOM(text) {
    const serializer = DOMSerializer.fromSchema(narrowsSchema);
    return serializer.serializeFragment(text.content);
}

function updateParticipants(editorView, participants) {
    editorView.props.participants = participants;
}

module.exports.schema = narrowsSchema;
module.exports.create = create;
module.exports.updateText = updateText;
module.exports.importText = importText;
module.exports.exportText = exportText;
module.exports.exportTextToDOM = exportTextToDOM;
module.exports.updateParticipants = updateParticipants;
