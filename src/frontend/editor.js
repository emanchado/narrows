const {EditorState} = require("prosemirror-state");
const {MenuBarEditorView} = require("prosemirror-menu");
const {Node, DOMSerializer} = require("prosemirror-model");
const {schema: narrowsSchema} = require("./narrows-schema");
const {editorSetup} = require("./setup");

function create(initialContent, place, onChangeHandler) {
    const state = EditorState.create({
        doc: importText(initialContent),
        plugins: editorSetup({schema: narrowsSchema})
    });

    const view = new MenuBarEditorView(place, {
        state: state,
        images: ["church.jpg", "charleston.jpg"],
        onAction(action) {
            onChangeHandler(action);
            view.updateState(view.editor.state.applyAction(action));
        }
    });

    return view;
}

function importText(text) {
    if (!text) {
        return null;
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

function addMention(editorView, characters) {
    const {from, to} = editorView.editor.state.selection;
    const mark = schema.mark("mention", {mentionTargets: characters});

    const transf = state.tr.addMark(from, to, mark);
    editorView.props.onAction(transf.scrollAction());
}

module.exports.schema = narrowsSchema;
module.exports.create = create;
module.exports.importText = importText;
module.exports.exportText = exportText;
module.exports.exportTextToDOM = exportTextToDOM;
module.exports.addMention = addMention;
