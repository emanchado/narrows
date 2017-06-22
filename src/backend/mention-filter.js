import util from "util";

function removeHiddenTextFromChunk(chunk, characterId) {
    if (chunk.type === "blockquote") {
        return removeMentions(Object.assign(
            {},
            chunk,
            { content: filterChunksFor(chunk.content, characterId) }
        ));
    }

    if (!util.isArray(chunk.content)) {
        return chunk;
    }

    return removeMentions(Object.assign(
        {},
        chunk,
        { content: chunk.content.filter(bit => {
            if (!("marks" in bit)) {
                return true;
            }

            const mentions = bit.marks.filter(m => m.type === "mention");
            return mentions.length === 0 || mentions.some(m => {
                return m.attrs &&
                    m.attrs.mentionTargets &&
                    m.attrs.mentionTargets.some(t => t.id === characterId);
            });
        }) }
    ));
}

function removeMentions(chunk) {
    if (!util.isArray(chunk.content)) {
        return chunk;
    }

    return Object.assign({},
                         chunk,
                         { content: chunk.content.map(removeMentionsFromBit) });
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
    const paragraphContentCopy = Object.assign({}, bit);

    delete paragraphContentCopy.marks;
    return Object.assign(paragraphContentCopy,
                         newMarks.length ? { marks: newMarks } : {});
}

function chunkEmpty(chunk) {
    return (
        (chunk.type === "paragraph" || chunk.type === "blockquote") &&
            (!chunk.content || chunk.content.length === 0)
    );
}

function filterChunksFor(chunkList, characterId) {
    return chunkList.map(chunk => (
        removeHiddenTextFromChunk(chunk, characterId)
    )).filter(
        chunk => !chunkEmpty(chunk)
    );
}

export function filter(documentObject, characterId) {
    return Object.assign(
        {},
        documentObject,
        { content: filterChunksFor(documentObject.content, characterId) }
    );
}

export default { filter };
