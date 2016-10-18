import test from "ava";
import fs from "fs-extra";
import NarrowsStore from "../src/backend/NarrowsStore";

const TEST_DB = "test.db";
const TEST_MIGRATED_DB = "test-migrated.db";
const TEST_FILES = "testfiles";
const DEFAULT_AUDIO = "creepy.mp3";
const DEFAULT_BACKGROUND = "house.jpg";
const CHAR1_NAME = "Frodo";
const CHAR1_TOKEN = "979021c8-97b4-11e6-a708-ff4e2821162e";
const CHAR2_NAME = "Sam";
const CHAR2_TOKEN = "bb0a38b4-97b4-11e6-906f-bfca08f8b9ae";

function createCharacter(store, characterName, characterToken) {
    return store.addCharacter(characterName, characterToken);
}

/**
 * Because running the migrations is ridiculously slow, we only do it
 * once in TEST_MIGRATED_DB, then copy that to TEST_DB before every
 * test.
 */
test.before(t => {
    const f = fs.openSync(TEST_MIGRATED_DB, "w+");
    fs.closeSync(f);

    const store = new NarrowsStore(TEST_MIGRATED_DB, TEST_FILES);
    return store.connect();
});

test.beforeEach(t => {
    fs.copySync(TEST_MIGRATED_DB, TEST_DB);
    fs.removeSync(TEST_FILES);
    fs.mkdirpSync(TEST_FILES);

    const store = new NarrowsStore(TEST_DB, TEST_FILES);
    return store.connect().then(() => {
        return store.createNarration({
            narratorId: 1,
            title: "Basic Test Narration",
            defaultAudio: DEFAULT_AUDIO,
            defaultBackgroundImage: DEFAULT_BACKGROUND
        });
    }).then(narration => {
        t.context.store = store;
        t.context.testNarration = narration;

        return createCharacter(t.context.store, CHAR1_NAME, CHAR1_TOKEN);
    }).then(characterId => {
        t.context.characterId1 = characterId;

        return createCharacter(t.context.store, CHAR2_NAME, CHAR2_TOKEN);
    }).then(characterId => {
        t.context.characterId2 = characterId;
    });
});

test.serial("can create a simple narration", t => {
    const props = {
        title: "Test Narration",
        defaultBackgroundImage: "bg.jpg",
        defaultAudio: "music.mp3"
    };

    return t.context.store.createNarration(props).then(narration => {
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
        participants: [1]
    };

    return t.context.store.createChapter(narrationId, props).then(chapter => {
        t.true(chapter.id > 0);
        t.is(chapter.narrationId, narrationId);
        t.is(chapter.title, "Intro");
        t.deepEqual(chapter.text, []);
    });
});

test.serial("uses background/audio from narration as defaults", t => {
    const narrationId = t.context.testNarration.id;
    const props = { title: "Intro", text: [], participants: [1] };

    return t.context.store.createChapter(narrationId, props).then(chapter => {
        t.is(chapter.audio, DEFAULT_AUDIO);
        t.is(chapter.backgroundImage, DEFAULT_BACKGROUND);
    });
});

test.serial("can set a specific audio for the chapter", t => {
    const narrationId = t.context.testNarration.id;
    const props = {
        title: "Intro",
        text: [],
        participants: [1],
        audio: "action.mp3"
    };

    return t.context.store.createChapter(narrationId, props).then(chapter => {
        t.is(chapter.audio, "action.mp3");
        t.is(chapter.backgroundImage, DEFAULT_BACKGROUND);
    });
});

test.serial("can set a specific background image for the chapter", t => {
    const narrationId = t.context.testNarration.id;
    const props = {
        title: "Intro",
        text: [],
        participants: [1],
        backgroundImage: "hostel.jpg"
    };

    return t.context.store.createChapter(narrationId, props).then(chapter => {
        t.is(chapter.audio, DEFAULT_AUDIO);
        t.is(chapter.backgroundImage, "hostel.jpg");

        return t.context.store.getChapter(chapter.id);
    }).then(chapter => {
        t.is(chapter.audio, DEFAULT_AUDIO);
        t.is(chapter.backgroundImage, "hostel.jpg");
    });
});

test.serial("can get the messages for a chapter", t => {
    const narrationId = t.context.testNarration.id;
    const props = { title: "Intro",
                    text: [],
                    participants: [1],
                    backgroundImage: "hostel.jpg" };
    let chapterId;

    return t.context.store.createChapter(narrationId, props).then(chapter => {
        chapterId = chapter.id;

        return t.context.store.addMessage(chapterId,
                                          t.context.characterId1,
                                          "Message from 1 to 2...",
                                          [t.context.characterId2]);
    }).then(() => {
        return t.context.store.addMessage(chapterId,
                                          t.context.characterId2,
                                          "Reply from 2 to 1...",
                                          [t.context.characterId1]);
    }).then(() => {
        return t.context.store.getChapterMessages(chapterId,
                                                  t.context.characterId1);
    }).then(messages => {
        t.is(messages.length, 2);
    });
});

test.serial("can get the messages to the narrator (no recipients)", t => {
    const narrationId = t.context.testNarration.id;
    const props = { title: "Intro",
                    text: [],
                    participants: [1],
                    backgroundImage: "hostel.jpg" };
    let chapterId;

    return t.context.store.createChapter(narrationId, props).then(chapter => {
        chapterId = chapter.id;

        return t.context.store.addMessage(chapterId,
                                          t.context.characterId1,
                                          "Message from 1 to narrator...",
                                          []);
    }).then(() => {
        return t.context.store.getChapterMessages(chapterId,
                                                  t.context.characterId1);
    }).then(messages => {
        t.is(messages.length, 1);
    });
});

test.afterEach.always(t => {
    fs.unlinkSync(TEST_DB);
});

test.after.always(t => {
    fs.unlinkSync(TEST_MIGRATED_DB);
});
