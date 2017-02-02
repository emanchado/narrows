function threadIdFor(message) {
    const recipienList = message.recipients || [];

    return recipienList.concat(message.sender).
        filter(character => character).
        map(character => character.id).
        sort().
        join("-");
}

export function threadMessages(messageList) {
    const threads = {};

    messageList.forEach(message => {
        const threadId = threadIdFor(message);

        threads[threadId] = threads[threadId] || [];
        threads[threadId].push(message);
    });

    return Object.keys(threads).
        map(threadId => threads[threadId]).
        sort((a, b) => {
            const lastTimestampA = a[a.length - 1].sentAt;
            const lastTimestampB = b[b.length - 1].sentAt;

            if (lastTimestampA < lastTimestampB) {
                return -1;
            }
            return lastTimestampA > lastTimestampB ? 1 : 0;
        }).
        map(messageGroup => {
            const randomMessage = messageGroup[0];
            const recipients = randomMessage.recipients || [];
            if (randomMessage.sender) {
                recipients.push(randomMessage.sender);
            }

            return {
                participants: recipients,
                messages: messageGroup
            };
        });
}

export default { threadMessages };
