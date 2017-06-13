import config from "config";
import Q from "q";

import Mailer from "../src/backend/Mailer";

export default function testcases(test, stash) {
    test.serial("can send a message from character to many characters", t => {
        const narrationId = t.context.testNarration.id;
        const props = {
            title: "Intro",
            text: [],
            participants: [{id: t.context.characterId1},
                           {id: t.context.characterId2},
                           {id: t.context.characterId3},
                           {id: t.context.characterId4}]
        };

        return stash.store.createChapter(narrationId, props).then(chapter => {
            const mailer = new Mailer(stash.store, null);
            const sendMailCalls = [];
            mailer.sendMail = (template, recipient, subject, stash) => {
                sendMailCalls.push({template, recipient, subject, stash});
            };

            const message = "First message";
            return Q.all([
                stash.store.getCharacterTokenById(t.context.characterId1),
                stash.store.getCharacterTokenById(t.context.characterId2),
                stash.store.getCharacterTokenById(t.context.characterId3),
                mailer.messagePosted({
                    chapterId: chapter.id,
                    recipients: [t.context.characterId2,
                                 t.context.characterId3],
                    sender: {id: t.context.characterId1,
                             name: stash.characterName1},
                    text: message
                })
            ]).spread((charToken1, charToken2, charToken3, _) => {
                const expectedSubject =
                      `${stash.characterName1} sent a message in "Intro"`;
                t.is(sendMailCalls.length, 3);
                t.deepEqual(
                    sendMailCalls.map(c => c.template),
                    ["messagePosted", "messagePosted", "messagePosted"]
                );

                t.is(sendMailCalls[0].recipient, stash.userEmail2);
                t.is(sendMailCalls[0].subject, expectedSubject);
                t.is(sendMailCalls[0].stash.messageText, message);
                t.is(sendMailCalls[0].stash.chapterUrl,
                     `${config.publicAddress}/read/${chapter.id}/${charToken2}`);
                t.is(sendMailCalls[0].stash.recipientListString,
                     `${stash.characterName3}, the narrator, and you`);

                t.is(sendMailCalls[1].recipient, stash.userEmail3);
                t.is(sendMailCalls[1].subject, expectedSubject);
                t.is(sendMailCalls[1].stash.messageText, message);
                t.is(sendMailCalls[1].stash.chapterUrl,
                     `${config.publicAddress}/read/${chapter.id}/${charToken3}`);
                t.is(sendMailCalls[1].stash.recipientListString,
                     `${stash.characterName2}, the narrator, and you`);

                t.is(sendMailCalls[2].recipient, stash.narratorEmail);
                t.is(sendMailCalls[2].subject, expectedSubject);
                t.is(sendMailCalls[2].stash.messageText, message);
                t.is(sendMailCalls[2].stash.chapterUrl,
                     `${config.publicAddress}/chapters/${chapter.id}`);
                t.is(sendMailCalls[2].stash.recipientListString,
                     `${stash.characterName2}, ${stash.characterName3}, and you`);
            });
        });
    });

    test.serial("can send a message from character to a narrator", t => {
        const narrationId = t.context.testNarration.id;
        const props = {
            title: "Intro",
            text: [],
            participants: [{id: t.context.characterId1},
                           {id: t.context.characterId2}]
        };

        return stash.store.createChapter(narrationId, props).then(chapter => {
            const mailer = new Mailer(stash.store, null);
            const sendMailCalls = [];
            mailer.sendMail = (template, recipient, subject, stash) => {
                sendMailCalls.push({template, recipient, subject, stash});
            };

            return mailer.messagePosted({
                chapterId: chapter.id,
                recipients: [],
                sender: {id: t.context.characterId1,
                         name: stash.characterName1},
                text: "First message"
            }).then(() => {
                const expectedSubject =
                      `${stash.characterName1} sent a message in "Intro"`;
                t.is(sendMailCalls.length, 1);

                t.is(sendMailCalls[0].recipient, stash.narratorEmail);
                t.is(sendMailCalls[0].subject, expectedSubject);
                t.is(sendMailCalls[0].stash.recipientListString, "you");
            });
        });
    });

    test.serial("can send a message from character to one character", t => {
        const narrationId = t.context.testNarration.id;
        const props = {
            title: "Intro",
            text: [],
            participants: [{id: t.context.characterId1},
                           {id: t.context.characterId2}]
        };

        return stash.store.createChapter(narrationId, props).then(chapter => {
            const mailer = new Mailer(stash.store, null);
            const sendMailCalls = [];
            mailer.sendMail = (template, recipient, subject, stash) => {
                sendMailCalls.push({template, recipient, subject, stash});
            };

            return mailer.messagePosted({
                chapterId: chapter.id,
                recipients: [t.context.characterId2],
                sender: {id: t.context.characterId1,
                         name: stash.characterName1},
                text: "First message"
            }).then(() => {
                const expectedSubject =
                      `${stash.characterName1} sent a message in "Intro"`;
                t.is(sendMailCalls.length, 2);

                t.is(sendMailCalls[0].recipient, stash.userEmail2);
                t.is(sendMailCalls[0].subject, expectedSubject);
                t.is(sendMailCalls[0].stash.recipientListString,
                     "the narrator and you");

                t.is(sendMailCalls[1].recipient, stash.narratorEmail);
                t.is(sendMailCalls[1].subject, expectedSubject);
                t.is(sendMailCalls[1].stash.recipientListString,
                     `${stash.characterName2} and you`);
            });
        });
    });

    test.serial("can send a message from narrator to a character", t => {
        const narrationId = t.context.testNarration.id;
        const props = {
            title: "Intro",
            text: [],
            participants: [{id: t.context.characterId1},
                           {id: t.context.characterId2}]
        };

        return stash.store.createChapter(narrationId, props).then(chapter => {
            const mailer = new Mailer(stash.store, null);
            const sendMailCalls = [];
            mailer.sendMail = (template, recipient, subject, stash) => {
                sendMailCalls.push({template, recipient, subject, stash});
            };

            return mailer.messagePosted({
                chapterId: chapter.id,
                recipients: [t.context.characterId1],
                sender: {id: null, name: "Narrator"},
                text: "First message"
            }).then(() => {
                const expectedSubject = `Narrator sent a message in "Intro"`;
                t.is(sendMailCalls.length, 1);

                t.is(sendMailCalls[0].recipient, stash.userEmail1);
                t.is(sendMailCalls[0].subject, expectedSubject);
                t.is(sendMailCalls[0].stash.recipientListString, "you");
            });
        });
    });

    test.serial("can send a message from narrator to several characters", t => {
        const narrationId = t.context.testNarration.id;
        const props = {
            title: "Intro",
            text: [],
            participants: [{id: t.context.characterId1},
                           {id: t.context.characterId2}]
        };

        return stash.store.createChapter(narrationId, props).then(chapter => {
            const mailer = new Mailer(stash.store, null);
            const sendMailCalls = [];
            mailer.sendMail = (template, recipient, subject, stash) => {
                sendMailCalls.push({template, recipient, subject, stash});
            };

            return mailer.messagePosted({
                chapterId: chapter.id,
                recipients: [t.context.characterId1, t.context.characterId2],
                sender: {id: null, name: "Narrator"},
                text: "First message"
            }).then(() => {
                const expectedSubject = `Narrator sent a message in "Intro"`;
                t.is(sendMailCalls.length, 2);

                t.is(sendMailCalls[0].recipient, stash.userEmail1);
                t.is(sendMailCalls[0].subject, expectedSubject);
                t.is(sendMailCalls[0].stash.recipientListString,
                     `${stash.characterName2} and you`);

                t.is(sendMailCalls[1].recipient, stash.userEmail2);
                t.is(sendMailCalls[1].subject, expectedSubject);
                t.is(sendMailCalls[1].stash.recipientListString,
                     `${stash.characterName1} and you`);
            });
        });
    });
};
