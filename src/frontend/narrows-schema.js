const {schema: baseSchema} = require("prosemirror-schema-basic");
const model = require("prosemirror-model"),
      Schema = model.Schema,
      Mark = model.Mark,
      MarkType = model.MarkType,
      Attribute = model.Attribute,
      Fragment = model.Fragment;
const {addListNodes} = require("prosemirror-schema-list");

const markSpec = baseSchema.markSpec.append({mention: {
    attrs: {
        mentionTargets: {default: []}
    },
    parseDOM: [{tag: "span[data-mentions]", getAttrs(dom) {
        return {mentionTargets: JSON.parse(dom.getAttribute("data-mentions"))};
    }}],
    toDOM(node) {
        const targets = node.attrs.mentionTargets;

        return [
            "span",
            {"data-mentions": JSON.stringify(targets),
             "class": "mention" + targets.map(t => ` mention-${t.id % 5 + 1}`).join(""),
             "title": "Only for " + targets.map(t => t.name).join(", ")
            }
        ];
    }
}});

const schema = new Schema({
  nodes: addListNodes(baseSchema.nodeSpec, "paragraph block*", "block"),
  marks: markSpec
});

module.exports.schema = schema;
