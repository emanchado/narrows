const prosemirror = require("prosemirror");
const schemaInfo = require("./narrows-schema"),
      narrowsSchema = schemaInfo.schema,
      MentionMark = schemaInfo.MentionMark;
const schemaBasic = require("prosemirror/dist/schema-basic"),
      BlockQuote = schemaBasic.BlockQuote;
const model = require("prosemirror/dist/model"),
      Schema = model.Schema,
      Mark = model.Mark,
      MarkType = model.MarkType,
      Attribute = model.Attribute,
      Fragment = model.Fragment,
      Node = model.Node;
const ir = require("prosemirror/dist/inputrules");

const proseMirrorPlugins = [
    ir.inputRules.config({
        rules: ir.allInputRules.concat(
            ir.blockQuoteRule(narrowsSchema.nodes.blockquote),
            ir.bulletListRule(narrowsSchema.nodes.bullet_list),
            ir.orderedListRule(narrowsSchema.nodes.ordered_list)
        )
    })
];

function create(initialContent, place) {
    return new prosemirror.ProseMirror({
        schema: narrowsSchema,
        plugins: proseMirrorPlugins,
        doc: initialContent,
        place: place
    });
}

function importText(text) {
    if (!text) {
        return null;
    }
    return Node.fromJSON(narrowsSchema, text);
}

function markTextForCharacter(editor, characters) {
    const {from, to} = editor.selection;

    var type = new MentionMark("mention", 0, narrowsSchema);
    editor.tr.addMark(
        from,
        to,
        type.create({ mentionTargets: characters })
    ).applyAndScroll();
}

module.exports.schema = narrowsSchema;
module.exports.create = create;
module.exports.importText = importText;
module.exports.markTextForCharacter = markTextForCharacter;
