var prosemirror = require("prosemirror");
var schemaInfo = require("./narrows-schema"),
    narrowsSchema = schemaInfo.schema,
    MentionMark = schemaInfo.MentionMark;
var model = require("prosemirror/dist/model"),
    Schema = model.Schema,
    Mark = model.Mark,
    MarkType = model.MarkType,
    Attribute = model.Attribute,
    Fragment = model.Fragment;
var inputRules = require("prosemirror/dist/inputrules");

var editor = new prosemirror.ProseMirror({
    place: document.getElementById("editor"),
    schema: narrowsSchema,
    plugins: [
        inputRules.inputRules.config({rules:
                                      inputRules.allInputRules.concat(inputRules.blockQuoteRule,
                                                                      inputRules.orderedListRule,
                                                                      inputRules.bulletListRule)})
    ]
});

var type = new MentionMark("mention", 0, narrowsSchema);

document.getElementById("btn-mark").addEventListener("click", function() {
    editor.tr.addMark(10, 35, type.create({mentionTarget: "Atana"})).applyAndScroll();
}, false);

let counter = 0;
document.getElementById("btn-mark").addEventListener("click", function() {
    editor.tr.addMark(10 + counter, 35 - counter, type.create({mentionTarget: "Atana " + counter++})).applyAndScroll();
}, false);

document.getElementById("btn-export").addEventListener("click", function() {
    var jsonDoc = editor.doc.toJSON();
    console.log(JSON.stringify(jsonDoc, null, 2));
    jsonDoc.content[0].content.splice(1, 1);
    console.log(JSON.stringify(jsonDoc, null, 2));

    // var f = Fragment.fromJSON(narrowsSchema, jsonDoc.content);
    // document.getElementById("result").appendChild(f.toDOM());
}, false);

document.getElementById("btn-save").addEventListener("click", function() {
    const jsonDoc = editor.doc.toJSON();
    console.log(JSON.stringify(jsonDoc, null, 2));

    const xhr = new XMLHTTPRequest();
    xhr.open("POST", "/api/fragments/" + fragmentId);
    xhr.setRequestHeader("Content-Type", "application/json");
    xhr.addEventListener("load", function() {
        if (this.status >= 400) {
            const response = JSON.parse(this.responseText);
            alert("Could not save fragment text: " + response.errorMessage);
            return;
        }
    });
    xhr.send(JSON.stringify({"fragmentText": jsonDoc}));

    // var f = Fragment.fromJSON(narrowsSchema, jsonDoc.content);
    // document.getElementById("result").appendChild(f.toDOM());
}, false);
