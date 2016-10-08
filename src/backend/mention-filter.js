import util from "util";

function merge(dst) {
    const origins = Array.prototype.slice.call(arguments, 1);

    origins.forEach(obj => {
        Object.keys(obj).forEach(key => {
            dst[key] = obj[key];
        });
    });

    return dst;
}

function skipContentNotFor(paragraphContent, characterId) {
    if (!util.isArray(paragraphContent)) {
        return paragraphContent;
    }

    return paragraphContent.filter(bit => {
        if (!("marks" in bit)) {
            return true;
        }

        const mentions = bit.marks.filter(m => m._ === "mention");
        return mentions.some(m => {
            return m.mentionTargets.some(t => t.id === characterId);
        });
    });
}

export function filter(documentObject, characterId) {
    const filteredContent = documentObject.content.map(para => {
        return merge(
            {},
            para,
            { content: skipContentNotFor(para.content, characterId) }
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