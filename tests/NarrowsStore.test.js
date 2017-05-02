import config from "config";
import test from "ava";
import fs from "fs-extra";
import Q from "q";
import { recreateDb } from "./test-utils.js";
import NarrowsStore from "../src/backend/NarrowsStore";
import UserStore from "../src/backend/UserStore";

const TEST_FILES = "testfiles";
const DEFAULT_AUDIO = "creepy.mp3";
const DEFAULT_BACKGROUND = "house.jpg";
const CHAR1_NAME = "Frodo";
const CHAR1_TOKEN = "979021c8-97b4-11e6-a708-ff4e2821162e";
const CHAR2_NAME = "Sam";
const CHAR2_TOKEN = "bb0a38b4-97b4-11e6-906f-bfca08f8b9ae";
const CHAR3_NAME = "Bilbo";
const CHAR3_TOKEN = "62963d86-a9cf-11e6-8fbb-f717783bbfc5";

// Cannot set t.context from "before", so just use global variables
let store, userStore, userId1, userId2, userId3;

// Because recreating the database is heavy, we do it only once for
// all tests, and then create a new narration for every test we run.
test.before(t => {
    // Recreate database
    return recreateDb(config.db).then(() => {
        store = new NarrowsStore(config.db, TEST_FILES);
        store.connect();
        userStore = new UserStore(config.db);
        userStore.connect();
        fs.removeSync(TEST_FILES);
        fs.mkdirpSync(TEST_FILES);

        return Q.all([userStore.createUser({ email: "test1@example.com" }),
                      userStore.createUser({ email: "test2@example.com" }),
                      userStore.createUser({ email: "test3@example.com" })]);
    }).spread((user1, user2, user3) => {
        userId1 = user1.id;
        userId2 = user2.id;
        userId3 = user3.id;
    });
});

test.beforeEach(t => {
    return store.createNarration({
        narratorId: 1,
        title: "Basic Test Narration",
        defaultAudio: DEFAULT_AUDIO,
        defaultBackgroundImage: DEFAULT_BACKGROUND
    }).then(narration => {
        t.context.testNarration = narration;

        return Q.all([
            store.addCharacter(CHAR1_NAME, userId1, narration.id),
            store.addCharacter(CHAR2_NAME, userId2, narration.id),
            store.addCharacter(CHAR3_NAME, userId3, narration.id)
        ]);
    }).spread((char1, char2, char3) => {
        t.context.characterId1 = char1.id;
        t.context.characterId2 = char2.id;
        t.context.characterId3 = char3.id;
    });
});

test.serial("can create a simple narration", t => {
    const props = {
        title: "Test Narration",
        defaultBackgroundImage: "bg.jpg",
        defaultAudio: "music.mp3"
    };

    return store.createNarration(props).then(narration => {
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

    return store.createChapter(narrationId, props).then(chapter => {
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

    return store.createChapter(narrationId, props).then(chapter => {
        t.is(chapter.audio, DEFAULT_AUDIO);
        t.is(chapter.backgroundImage, DEFAULT_BACKGROUND);
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

    return store.createChapter(narrationId, props).then(chapter => {
        t.is(chapter.audio, "action.mp3");
        t.is(chapter.backgroundImage, DEFAULT_BACKGROUND);
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

    return store.createChapter(narrationId, props).then(chapter => {
        t.is(chapter.audio, DEFAULT_AUDIO);
        t.is(chapter.backgroundImage, "hostel.jpg");

        return store.getChapter(chapter.id);
    }).then(chapter => {
        t.is(chapter.audio, DEFAULT_AUDIO);
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

    return store.createChapter(narrationId, props).then(chapter => {
        chapterId = chapter.id;

        return store.addMessage(chapterId,
                                t.context.characterId1,
                                "Message from 1 to 2...",
                                [t.context.characterId2]);
    }).then(() => {
        return store.addMessage(chapterId,
                                t.context.characterId2,
                                "Reply from 2 to 1...",
                                [t.context.characterId1]);
    }).then(() => {
        return store.getChapterMessages(chapterId,
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

    return store.createChapter(narrationId, props).then(chapter => {
        chapterId = chapter.id;

        return store.addMessage(chapterId,
                                t.context.characterId1,
                                "Message from 1 to narrator...",
                                []);
    }).then(() => {
        return store.getChapterMessages(chapterId,
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

    return store.createChapter(narrationId, props).then(chapter => {
        chapterId = chapter.id;

        return store.addMessage(chapterId,
                                t.context.characterId1,
                                "Message from 1 to 2...",
                                [t.context.characterId2,
                                 t.context.characterId3]);
    }).then(() => {
        return store.getChapterMessages(chapterId,
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
    let chapterId1, chapterId2, chapterId3;

    return store.createChapter(
        ctx.testNarration.id,
        chapterProps1
    ).then(chapter => {
        chapterId1 = chapter.id;

        return store.updateReaction(
            chapterId1, ctx.characterId1, "Character 1 reaction"
        );
    }).then(() => (
        store.createChapter(
            ctx.testNarration.id,
            chapterProps2
        )
    )).then(chapter => {
        chapterId2 = chapter.id;

        return store.updateReaction(
            chapterId2, ctx.characterId2, "Character 2 reaction"
        );
    }).then(() => (
        store.createChapter(
            ctx.testNarration.id,
            chapterProps3
        )
    )).then(chapter => {
        chapterId3 = chapter.id;

        return store.getChapterLastReactions(chapterId3);
    }).then(lastReactions => {
        t.is(lastReactions.length, 2);
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

    return store.createChapter(
        ctx.testNarration.id,
        chapterProps1
    ).then(() => (
        store.createChapter(
            ctx.testNarration.id,
            chapterProps2
        )
    )).then(chapter => (
        store.getFullCharacterStats(ctx.characterId1)
    )).then(stats => {
        t.is(stats.narration.chapters.length, 1);
    });
});

test.after.always(t => {
    fs.removeSync(TEST_FILES);
});
