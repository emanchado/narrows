import messageUtils from "./message-utils";

export function formatLastReactions(lastChapters) {
    return {
        lastChapters: lastChapters.map(lastChapter => ({
            id: lastChapter.id,
            title: lastChapter.title,
            text: JSON.parse(lastChapter.text.replace(/\r/g, "")),
            participants: lastChapter.participants,
            messageThreads: messageUtils.threadMessages(lastChapter.messages)
        }))
    };
}

export default { formatLastReactions };
