import RSS from "rss";

function escapeHTML(text) {
    return text.
        replace(new RegExp(/&/g), '&amp;').
        replace(new RegExp(/</g), '&lt;').
        replace(new RegExp(/>/g), '&gt;');
}

function makeCharacterFeed(baseUrl, character, store) {
    const feed = new RSS({
        title: `News for ${ character.name } — Narrows`,
        feed_url: `${ baseUrl }/feeds/${ character.token }`,
        site_url: baseUrl
    });

    return store.getActiveChapter(character.id).then(chapter => {
        const chapterUrl =
                  `https://narrows.hcoder.org/read/${ chapter.id }/${ character.token }`;

        feed.item({
            title: `New chapter "${ chapter.title }"`,
            description: `A new chapter, titled "${ chapter.title }",` +
                ` has been published.`,
            url: chapterUrl,
            guid: `new-chapter-${ chapter.id }`,
            date: chapter.published
        });

        return store.getChapterMessages(chapter.id, character.id).then(messages => {
            messages.forEach(message => {
                const senderName = message.sender ?
                          message.sender.name : "Narrator";

                if (message.sender && message.sender.id !== character.id) {
                    const recipientList =
                              message.recipients.map(r => (
                                  r.id === character.id ?
                                      "<em>you</em>" : escapeHTML(r.name)
                              )).join(", ");
                    const description =
                              `<p>Talking to ${ recipientList }:</p>\n<p>${ escapeHTML(message.body) }</p>`;

                    feed.item({
                        title: `Message from ${ escapeHTML(senderName) } in "${ escapeHTML(chapter.title) }"`,
                        description: description,
                        url: chapterUrl,
                        guid: `${ chapter.id }-${ character.token }-${ message.id }`,
                        date: message.sentAt
                    });
                }
            });

            return feed.xml({ indent: true });
        });
    });
}

export default { makeCharacterFeed };
