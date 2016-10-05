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

test("leaves alone simple mentions", t => {
    const orig = doc([
        para(["This is ",
              mentioned("INDEED ", [CHARACTER1]),
             "for me"])
    ]);

    t.deepEqual(mentionFilter.filter(orig, CHARACTER1.id), orig);
});

test("leaves alone mentions even when they include other characters", t => {
    const orig = doc([
        para(["This is ",
              mentioned("INDEED ", [CHARACTER1, CHARACTER2]),
             "for me"])
    ]);

    t.deepEqual(mentionFilter.filter(orig, CHARACTER1.id), orig);
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
