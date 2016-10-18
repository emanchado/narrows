function threadIdFor(message) {
    const recipienList = message.recipients || [];

    return recipienList.concat(message.sender).
        filter(character => character).
        map(character => character.id).
        sort().
        join("-");
}

function threadMessages(messageList) {
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

            return parseInt(lastTimestampA.replace(/[^0-9]/g, ''), 10) -
                parseInt(lastTimestampB.replace(/[^0-9]/g, ''), 10);
        }).
        map(messageGroup => {
            const randomMessage = messageGroup[0];
            const recipients = randomMessage.recipients || [];

            return {
                participants: recipients.concat(randomMessage.sender),
                messages: messageGroup
            };
        });
}

export default { threadMessages };
