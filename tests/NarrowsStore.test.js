import test from "ava";
import fs from "fs-extra";
import NarrowsStore from "../src/backend/NarrowsStore";

const TEST_DB = "test.db";
const TEST_MIGRATED_DB = "test-migrated.db";
const TEST_FILES = "testfiles";
const DEFAULT_AUDIO = "creepy.mp3";
const DEFAULT_BACKGROUND = "house.jpg";

/**
 * Because running the migrations is ridiculously slow, we only do it
 * once in TEST_MIGRATED_DB, then copy that to TEST_DB before every
 * test.
 */
test.before(t => {
    const f = fs.openSync(TEST_MIGRATED_DB, "w+");
    fs.closeSync(f);

    console.log("Now connecting to cached");
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
            title: "Basic Test Narration",
            defaultAudio: DEFAULT_AUDIO,
            defaultBackgroundImage: DEFAULT_BACKGROUND
        });
    }).then(narration => {
        t.context.store = store;
        t.context.testNarration = narration;
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

test.serial("can create a simple fragment", t => {
    const narrationId = t.context.testNarration.id;
    const props = {
        title: "Intro",
        text: [],
        participants: [1]
    };

    return t.context.store.createFragment(narrationId, props).then(fragment => {
        t.true(fragment.id > 0);
        t.is(fragment.narrationId, narrationId);
        t.is(fragment.title, "Intro");
        t.deepEqual(fragment.text, []);
    });
});

test.serial("uses background/audio from narration as defaults", t => {
    const narrationId = t.context.testNarration.id;
    const props = { title: "Intro", text: [], participants: [1] };

    return t.context.store.createFragment(narrationId, props).then(fragment => {
        t.is(fragment.audio, DEFAULT_AUDIO);
        t.is(fragment.backgroundImage, DEFAULT_BACKGROUND);
    });
});

test.serial("can set a specific audio for the fragment", t => {
    const narrationId = t.context.testNarration.id;
    const props = {
        title: "Intro",
        text: [],
        participants: [1],
        audio: "action.mp3"
    };

    return t.context.store.createFragment(narrationId, props).then(fragment => {
        t.is(fragment.audio, "action.mp3");
        t.is(fragment.backgroundImage, DEFAULT_BACKGROUND);
    });
});

test.serial("can set a specific background image for the fragment", t => {
    const narrationId = t.context.testNarration.id;
    const props = {
        title: "Intro",
        text: [],
        participants: [1],
        backgroundImage: "hostel.jpg"
    };

    return t.context.store.createFragment(narrationId, props).then(fragment => {
        t.is(fragment.audio, DEFAULT_AUDIO);
        t.is(fragment.backgroundImage, "hostel.jpg");
    });
});

test.afterEach.always(t => {
    fs.unlinkSync(TEST_DB);
});

test.after.always(t => {
    fs.unlinkSync(TEST_MIGRATED_DB);
});
