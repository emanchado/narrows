const schemaBasic = require("prosemirror/dist/schema-basic");
const model = require("prosemirror/dist/model"),
      Schema = model.Schema,
      Mark = model.Mark,
      MarkType = model.MarkType,
      Attribute = model.Attribute,
      Fragment = model.Fragment;

class MentionMark extends MarkType {
    get attrs() {
        return {
            mentionTarget: new Attribute()
        };
    }
    get matchDOMTag() {
        return {"div[data-mention]": dom => ({
            mentionTarget: dom.getAttribute("data-mention")
        })};
    }
    toDOM(node) { return ["span", {"data-mention": node.attrs.mentionTarget,
                                   "class": "mention",
                                   "title": node.attrs.mentionTarget}]; }
}

const narrowsSchema = new Schema({
  nodes: {
    doc: {type: schemaBasic.Doc, content: "block+"},

    paragraph: {type: schemaBasic.Paragraph, content: "inline<_>*", group: "block"},
    blockquote: {type: schemaBasic.BlockQuote, content: "block+", group: "block"},
    ordered_list: {type: schemaBasic.OrderedList, content: "list_item+", group: "block"},
    bullet_list: {type: schemaBasic.BulletList, content: "list_item+", group: "block"},
    horizontal_rule: {type: schemaBasic.HorizontalRule, group: "block"},
    heading: {type: schemaBasic.Heading, content: "inline<_>*", group: "block"},
    code_block: {type: schemaBasic.CodeBlock, content: "text*", group: "block"},

    list_item: {type: schemaBasic.ListItem, content: "paragraph block*"},

    text: {type: schemaBasic.Text, group: "inline"},
    image: {type: schemaBasic.Image, group: "inline"},
    hard_break: {type: schemaBasic.HardBreak, group: "inline"}
  },

  marks: {
    em: schemaBasic.EmMark,
    strong: schemaBasic.StrongMark,
    link: schemaBasic.LinkMark,
    code: schemaBasic.CodeMark,
    mention: MentionMark
  }
});

module.exports.schema = narrowsSchema;
module.exports.MentionMark = MentionMark;
module.exports.Image = schemaBasic.Image;
