import Q from "q";
import apiFormatter from "../src/backend/api-formatter";

export default function testcases(test, stash) {
    test.serial("can create a simple narration", t => {
        const props = {
            title: "Test Narration",
            defaultBackgroundImage: "bg.jpg",
            defaultAudio: "music.mp3"
        };

        return stash.store.createNarration(props).then(narration => {
            t.true(narration.id > 0);
            t.not(narration.id, t.context.testNarration.id);
            t.is(narration.title, "Test Narration");
            t.is(narration.defaultBackgroundImage, "bg.jpg");
            t.is(narration.defaultAudio, "music.mp3");
        });
    });

    test.serial("can create a simple chapter", t => {
        const narrationId = t.context.testNarration.id;
        const props = {
            title: "Intro",
            text: [],
            participants: [{id: t.context.characterId1}]
        };

        return stash.store.createChapter(narrationId, props).then(chapter => {
            t.true(chapter.id > 0);
            t.is(chapter.narrationId, narrationId);
            t.is(chapter.title, "Intro");
            t.deepEqual(chapter.text, []);
        });
    });

    test.serial("uses background/audio from narration as defaults", t => {
        const narrationId = t.context.testNarration.id;
        const character = {id: t.context.characterId1};
        const props = { title: "Intro", text: [], participants: [character] };

        return stash.store.createChapter(narrationId, props).then(chapter => {
            t.is(chapter.audio, stash.defaultAudio);
            t.is(chapter.backgroundImage, stash.defaultBackground);
        });
    });

    test.serial("can set a specific audio for the chapter", t => {
        const narrationId = t.context.testNarration.id;
        const props = {
            title: "Intro",
            text: [],
            participants: [{id: t.context.characterId1}],
            audio: "action.mp3"
        };

        return stash.store.createChapter(narrationId, props).then(chapter => {
            t.is(chapter.audio, "action.mp3");
            t.is(chapter.backgroundImage, stash.defaultBackground);
        });
    });

    test.serial("can set a specific background image for the chapter", t => {
        const narrationId = t.context.testNarration.id;
        const props = {
            title: "Intro",
            text: [],
            participants: [{id: t.context.characterId1}],
            backgroundImage: "hostel.jpg"
        };

        return stash.store.createChapter(narrationId, props).then(chapter => {
            t.is(chapter.audio, stash.defaultAudio);
            t.is(chapter.backgroundImage, "hostel.jpg");

            return stash.store.getChapter(chapter.id);
        }).then(chapter => {
            t.is(chapter.audio, stash.defaultAudio);
            t.is(chapter.backgroundImage, "hostel.jpg");
        });
    });

    test.serial("can get the messages for a chapter", t => {
        const narrationId = t.context.testNarration.id;
        const props = { title: "Intro",
                        text: [],
                        participants: [{id: t.context.characterId1}],
                        backgroundImage: "hostel.jpg" };
        let chapterId;

        return stash.store.createChapter(narrationId, props).then(chapter => {
            chapterId = chapter.id;

            return stash.store.addMessage(chapterId,
                                    t.context.characterId1,
                                    "Message from 1 to 2...",
                                    [t.context.characterId2]);
        }).then(() => {
            return stash.store.addMessage(chapterId,
                                    t.context.characterId2,
                                    "Reply from 2 to 1...",
                                    [t.context.characterId1]);
        }).then(() => {
            return stash.store.getChapterMessages(chapterId,
                                            t.context.characterId1);
        }).then(messages => {
            t.is(messages.length, 2);
        });
    });

    test.serial("can get the messages to the narrator (no recipients)", t => {
        const narrationId = t.context.testNarration.id;
        const props = { title: "Intro",
                        text: [],
                        participants: [{id: t.context.characterId1}],
                        backgroundImage: "hostel.jpg" };
        let chapterId;

        return stash.store.createChapter(narrationId, props).then(chapter => {
            chapterId = chapter.id;

            return stash.store.addMessage(chapterId,
                                    t.context.characterId1,
                                    "Message from 1 to narrator...",
                                    []);
        }).then(() => {
            return stash.store.getChapterMessages(chapterId,
                                            t.context.characterId1);
        }).then(messages => {
            t.is(messages.length, 1);
        });
    });

    test.serial("messages are only added once", t => {
        const narrationId = t.context.testNarration.id;
        const props = { title: "Intro",
                        text: [],
                        participants: [{id: t.context.characterId1}],
                        backgroundImage: "hostel.jpg" };
        let chapterId;

        return stash.store.createChapter(narrationId, props).then(chapter => {
            chapterId = chapter.id;

            return stash.store.addMessage(chapterId,
                                    t.context.characterId1,
                                    "Message from 1 to 2...",
                                    [t.context.characterId2,
                                     t.context.characterId3]);
        }).then(() => {
            return stash.store.getChapterMessages(chapterId,
                                            t.context.characterId1);
        }).then(messages => {
            t.is(messages.length, 1);
        });
    });

    test.serial("last reactions work when different characters last appeared in different chapters", t => {
        const ctx = t.context;
        const chapterProps1 = { title: "Intro for char1",
                                text: [],
                                participants: [{id: ctx.characterId1}],
                                published: new Date() };
        const chapterProps2 = { title: "Intro for char2",
                                text: [],
                                participants: [{id: ctx.characterId2}],
                                published: new Date() };
        const chapterProps3 = { title: "First joint chapter",
                                text: [],
                                participants: [{id: ctx.characterId1},
                                               {id: ctx.characterId2}] };
        let chapterId3;

        return Q.all([
            stash.store.createChapter(ctx.testNarration.id, chapterProps1),
            stash.store.createChapter(ctx.testNarration.id, chapterProps2),
            stash.store.createChapter(ctx.testNarration.id, chapterProps3)
        ]).spread((chapter1, chapter2, chapter3) => {
            chapterId3 = chapter3.id;

            return Q.all([
                stash.store.addMessage(chapter1.id, ctx.characterId1, "Reaction 1", []),
                stash.store.addMessage(chapter2.id, ctx.characterId2, "Reaction 2", [])
            ]);
        }).then(() => (
            stash.store.getChapterLastReactions(chapterId3)
        )).then(lastReactions => {
            t.is(lastReactions.length, 2);
        });
    });

    // This test is specifically for the formatLastReactions function, but
    // it's a pain to setup another file with its own database just for
    // it, so at least for now it's here.
    test.serial("last reactions should return last-appearance chapters", t => {
        const ctx = t.context;
        const chapterProps1 = { title: "Intro for char1",
                                text: [],
                                participants: [{id: ctx.characterId1}],
                                published: new Date() };
        const chapterProps2 = { title: "Intro for char2 and char3",
                                text: [],
                                participants: [{id: ctx.characterId2},
                                               {id: ctx.characterId3}],
                                published: new Date() };
        const chapterProps3 = { title: "All together now!",
                                text: [],
                                participants: [{id: ctx.characterId1},
                                               {id: ctx.characterId2},
                                               {id: ctx.characterId3}] };
        let chapterId1, chapterId2, chapterId3;

        return Q.all([
            stash.store.createChapter(ctx.testNarration.id, chapterProps1),
            stash.store.createChapter(ctx.testNarration.id, chapterProps2),
            stash.store.createChapter(ctx.testNarration.id, chapterProps3)
        ]).spread((chapter1, chapter2, chapter3) => {
            chapterId1 = chapter1.id;
            chapterId2 = chapter2.id;
            chapterId3 = chapter3.id;

            return Q.all([
                stash.store.addMessage(chapterId1, ctx.characterId1, "Reaction 1", []),
                stash.store.addMessage(chapterId2, ctx.characterId2, "Reaction 2", []),
                stash.store.addMessage(chapterId2, ctx.characterId3, "Reaction 3", []),
            ]);
        }).then(() => (
            stash.store.getChapterLastReactions(chapterId3)
        )).then(reactions => {
            const formattedResponse =
                  apiFormatter.formatLastReactions(reactions);

            t.is(formattedResponse.lastChapters.length, 2);
        });
    });

    test.serial("character stats only lists chapters the character has appeared in", t => {
        const ctx = t.context;
        const chapterProps1 = { title: "Intro for char1",
                                text: [],
                                participants: [{id: ctx.characterId1}],
                                published: new Date() };
        const chapterProps2 = { title: "Intro for char2",
                                text: [],
                                participants: [{id: ctx.characterId2}],
                                published: new Date() };

        return stash.store.createChapter(
            ctx.testNarration.id,
            chapterProps1
        ).then(() => (
            stash.store.createChapter(
                ctx.testNarration.id,
                chapterProps2
            )
        )).then(chapter => (
            stash.store.getFullCharacterStats(ctx.characterId1)
        )).then(stats => {
            t.is(stats.narration.chapters.length, 1);
        });
    });
};
