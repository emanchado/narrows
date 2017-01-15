import util from "util";
import merge from "./merge";

function skipContentNotFor(paragraphContent, characterId) {
    if (!util.isArray(paragraphContent)) {
        return paragraphContent;
    }

    return paragraphContent.filter(bit => {
        if (!("marks" in bit)) {
            return true;
        }

        const mentions = bit.marks.filter(m => m.type === "mention");
        return mentions.length === 0 || mentions.some(m => {
            return m.attrs &&
                m.attrs.mentionTargets &&
                m.attrs.mentionTargets.some(t => t.id === characterId);
        });
    });
}

function removeMentions(paragraphContent) {
    if (!util.isArray(paragraphContent)) {
        return paragraphContent;
    }

    return paragraphContent.map(removeMentionsFromBit);
}

function removeMentionsFromBit(bit) {
    if (!util.isObject(bit)) {
        return bit;
    }

    const marks = bit.marks;
    if (!util.isArray(marks)) {
        return bit;
    }

    const newMarks = marks.filter(m => m.type !== "mention");
    const paragraphContentCopy = merge({}, bit);

    delete paragraphContentCopy.marks;
    return merge(paragraphContentCopy,
                 newMarks.length ? { marks: newMarks } : {});
}

export function filter(documentObject, characterId) {
    const filteredContent = documentObject.content.map(para => {
        return merge(
            {},
            para,
            { content: removeMentions(skipContentNotFor(para.content, characterId)) }
        );
    }).filter(para => {
        if (para.type !== "paragraph") {
            return true;
        }

        return para.content.length > 0;
    });

    return merge({}, documentObject, { content: filteredContent });
}

export default { filter };
