import test from "ava";
import { threadMessages } from "../src/backend/message-utils";

const CHAR1 = { id: 1, name: "Ada Arnstein" };
const CHAR2 = { id: 2, name: "Billy Bob" };
const CHAR3 = { id: 3, name: "Crystal Clear" };

test("no messages -> no threads", t => {
    t.deepEqual(threadMessages([]), []);
});

test("one message is one thread", t => {
    const messages = [ { recipients: [ CHAR2 ],
                         sender: CHAR1,
                         body: "First test message!",
                         sentAt: "2016-11-13 18:39" } ];
    const expectedThreads = [ { participants: [ CHAR2, CHAR1 ],
                                messages: messages } ];

    t.deepEqual(threadMessages(messages), expectedThreads);
});

test("messages with same participants are one thread", t => {
    const messages = [ { recipients: [ CHAR2 ],
                         sender: CHAR1,
                         body: "First test message!",
                         sentAt: "2016-11-13 18:39" },
                       { recipients: [ CHAR1 ],
                         sender: CHAR2,
                         body: "Reply to that first message",
                         sentAt: "2016-11-13 18:48" } ];
    const expectedThreads = [ { participants: [ CHAR2, CHAR1 ],
                                messages: messages } ];

    t.deepEqual(threadMessages(messages), expectedThreads);
});

test("messages with different participants are different threads", t => {
    const messages = [ { recipients: [ CHAR2 ],
                         sender: CHAR1,
                         body: "First test message!",
                         sentAt: "2016-11-13 18:39" },
                       { recipients: [ CHAR1 ],
                         sender: CHAR3,
                         body: "Here comes a new challenger",
                         sentAt: "2016-11-13 18:50" } ];
    const expectedThreads = [ { participants: [ CHAR2, CHAR1 ],
                                messages: [ messages[0] ] },
                              { participants: [ CHAR1, CHAR3 ],
                                messages: [ messages[1] ] } ];

    t.deepEqual(threadMessages(messages), expectedThreads);
});

test("threads are sorted by most recent message's sent date", t => {
    const messages = [ { recipients: [ CHAR2 ],
                         sender: CHAR1,
                         body: "First test message!",
                         sentAt: "2016-11-13 18:39" },
                       { recipients: [ CHAR1 ],
                         sender: CHAR3,
                         body: "Here comes a new challenger",
                         sentAt: "2016-11-13 18:50" },
                       { recipients: [ CHAR1 ],
                         sender: CHAR2,
                         body: "Reply to that first message",
                         sentAt: "2016-11-13 19:05" } ];
    const expectedThreads = [ { participants: [ CHAR1, CHAR3 ],
                                messages: [ messages[1] ] },
                              { participants: [ CHAR2, CHAR1 ],
                                messages: [ messages[0], messages[2] ] } ];

    t.deepEqual(threadMessages(messages), expectedThreads);
});

test("narrator messages are included", t => {
    const messages = [ { recipients: [ CHAR2 ],
                         sender: null,
                         body: "Your narrator speaking",
                         sentAt: "2016-11-13 19:05" } ];
    const expectedThreads = [ { participants: [ CHAR2 ],
                                messages: messages } ];

    t.deepEqual(threadMessages(messages), expectedThreads);
});
