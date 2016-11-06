import test from "ava";
import mentionFilter from "../src/backend/mention-filter";

const CHARACTER1 = { "id": 1, "name": "Mildred Mayfield" };
const CHARACTER2 = { "id": 2, "name": "Frank Mayfield" };
const CHARACTER3 = { "id": 3, "name": "George Miller" };

function doc(spec) {
    return { type: "doc", content: spec };
}

function para(spec) {
    return {
        type: "paragraph",
        content: spec.map(s => {
            switch (typeof s) {
            case "string": return { type: "text", "text": s };
            default: return s;
            }
        })
    };
}

function mentioned(text, mentions) {
    return {
        type: "text",
        text: text,
        marks: [ { _: "mention", mentionTargets: mentions } ]
    };
}

test("filters out simple sentences", t => {
    const orig = doc([
        para(["This is ",
              mentioned("DEFINITELY NOT ", [CHARACTER1, CHARACTER2]),
             "fun"])
    ]);
    const expected = doc([ para(["This is ", "fun"]) ]);

    t.deepEqual(mentionFilter.filter(orig, CHARACTER3.id), expected);
});

test("doesn't modify the given parameter", t => {
    const orig = doc([
        para(["This is ",
              mentioned("DEFINITELY NOT ", [CHARACTER1, CHARACTER2]),
             "fun"])
    ]);
    const filtered = mentionFilter.filter(orig, CHARACTER3.id);

    t.notDeepEqual(filtered, orig);
});

test("leaves alone simple mention text", t => {
    const orig = doc([
        para(["This is ",
              mentioned("INDEED ", [CHARACTER1]),
             "for me"])
    ]);
    const expected = doc([ para(["This is ", "INDEED ", "for me"]) ]);

    t.deepEqual(mentionFilter.filter(orig, CHARACTER1.id), expected);
});

test("leaves alone mention text even when they include other characters", t => {
    const orig = doc([
        para(["This is ",
              mentioned("INDEED ", [CHARACTER1, CHARACTER2]),
             "for me"])
    ]);
    const expected = doc([ para(["This is ", "INDEED ", "for me"]) ]);

    t.deepEqual(mentionFilter.filter(orig, CHARACTER1.id), expected);
});

test("removes empty paragraphs", t => {
    const orig = doc([
        para([mentioned("Whole paragraph for Character 1", [CHARACTER1])]),
        para(["Another paragraph for everyone"])
    ]);
    const expected = doc([
        para(["Another paragraph for everyone"])
    ]);

    t.deepEqual(mentionFilter.filter(orig, CHARACTER2.id), expected);
});

test("leaves out the mention marks themselves", t => {
    const orig = doc([
        para([mentioned("Whole paragraph for Character 1", [CHARACTER1])]),
        para(["Another paragraph for everyone"])
    ]);
    const expected = doc([
        para(["Whole paragraph for Character 1"]),
        para(["Another paragraph for everyone"])
    ]);

    t.deepEqual(mentionFilter.filter(orig, CHARACTER1.id), expected);
});

test("leave alone other marks when removing mentions", t => {
    const text = "Blah blah";
    const text2 = "Blah blah blah";
    const orig = doc([
        para([{
            type: "text",
            text: text,
            marks: [ { _: "mention", mentionTargets: [{id: 1, name: "C1"}] },
                     { _: "unrelated-mark", level: "high" } ]
        }]),

        para([{
            type: "text",
            text: text2,
            marks: [ { _: "another", someExtraValue: "extra-good" } ]
        }])
    ]);
    const expected = doc([
        para([{
            type: "text",
            text: text,
            marks: [ { _: "unrelated-mark", level: "high" } ]
        }]),

        para([{
            type: "text",
            text: text2,
            marks: [ { _: "another", someExtraValue: "extra-good" } ]
        }])
    ]);

    t.deepEqual(mentionFilter.filter(orig, CHARACTER1.id), expected);
});

test("doesn't freak out with non-array block content", t => {
    const orig = doc([ {type: "image", content: "/images/logo.png"} ]);

    t.deepEqual(mentionFilter.filter(orig, CHARACTER1.id), orig);
});
