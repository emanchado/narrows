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

function objectEquals(x, y) {
    if (x === null || x === undefined || y === null || y === undefined) { return x === y; }
    if (x === y || x.valueOf() === y.valueOf()) { return true; }
    if (Array.isArray(x) && x.length !== y.length) { return false; }

    // if they are strictly equal, they both need to be object at least
    if (!(x instanceof Object) || !(y instanceof Object)) { return false; }

    // recursive object equality check
    var p = Object.keys(x);
    return Object.keys(y).every(function (i) { return p.indexOf(i) !== -1; }) &&
        p.every(function (i) { return objectEquals(x[i], y[i]); });
}


function create(initialContent, schema, place, onChangeHandler) {
    const view = new EditorView(place, {
        state: _textToState(initialContent, schema),
        images: [],
        dispatchTransaction: tr => {
            const newState = view.state.apply(tr);
            const originalDoc = view.state.toJSON().doc;
            const updatedDoc = newState.toJSON().doc;
            view.updateState(newState);

            if (!objectEquals(originalDoc, updatedDoc)) {
                onChangeHandler(view);
            }
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
