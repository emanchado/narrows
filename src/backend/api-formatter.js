export function formatLastReactions(chapterId, lastReactions) {
    const lastChapters = {};

    lastReactions.forEach(reaction => {
        if (reaction.chapterId in lastChapters) {
            return;
        }

        lastChapters[reaction.chapterId] = { id: reaction.chapterId,
                                             title: reaction.chapterTitle,
                                             text: reaction.chapterText };
    });

    return {
        chapterId: chapterId,
        lastReactions: lastReactions.map(reaction => (
            { chapter: { id: reaction.chapterId,
                         title: reaction.chapterTitle },
              character: { id: reaction.characterId,
                           name: reaction.characterName },
              text: reaction.text }
        )),
        lastChapters: Object.keys(lastChapters).map(chapter => (
            { id: lastChapters[chapter].id,
              title: lastChapters[chapter].title,
              text: JSON.parse(lastChapters[chapter].text) }
        ))
    };
}

export default { formatLastReactions };
