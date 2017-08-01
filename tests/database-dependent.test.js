import config from "config";
import test from "ava";
import fs from "fs-extra";
import Q from "q";
import { recreateDb } from "./test-utils.js";
import apiFormatter from "../src/backend/api-formatter";
import NarrowsStore from "../src/backend/NarrowsStore";
import UserStore from "../src/backend/UserStore";

import mailerTestcases from "./Mailer.testcases.js";
import narrowsStoreTestcases from "./NarrowsStore.testcases.js";

const TEST_FILES = "testfiles";

// Cannot set t.context from "before", so just use global variables
const store = new NarrowsStore(config.db, TEST_FILES);
let narratorUserId, userId1, userId2, userId3, userId4;

const DEFAULT_AUDIO = "creepy.mp3";
const DEFAULT_BACKGROUND = "house.jpg";
const NARRATOR_EMAIL = "narrator@example.com";
const USER1_EMAIL = "test1@example.com";
const USER2_EMAIL = "test2@example.com";
const USER3_EMAIL = "test3@example.com";
const USER4_EMAIL = "test4@example.com";
const CHAR1_NAME = "Frodo";
const CHAR2_NAME = "Sam";
const CHAR3_NAME = "Bilbo";
const CHAR4_NAME = "Pippin";

function createUsers(userStore, emailList) {
    let promise = Q([]);

    emailList.forEach(email => {
        promise = promise.then(partialRes => (
            userStore.createUser({ email: email }).then(user => (
                partialRes.concat(user)
            ))
        ));
    });

    return promise;
}

function createCharacters(store, characters) {
    let promise = Q([]);

    characters.forEach(characterParams => {
        promise = promise.then(partialRes => (
            store.addCharacter.apply(store, characterParams).then(char => (
                partialRes.concat(char)
            ))
        ));
    });

    return promise;
}

// Because recreating the database is heavy, we do it only once for
// all tests, and then create a new narration for every test we run.
test.before(t => {
    // Recreate database
    return recreateDb(config.db).then(() => {
        store.connect();
        const userStore = new UserStore(config.db);
        userStore.connect();
        fs.removeSync(TEST_FILES);
        fs.mkdirpSync(TEST_FILES);

        return createUsers(userStore, [NARRATOR_EMAIL,
                                       USER1_EMAIL,
                                       USER2_EMAIL,
                                       USER3_EMAIL,
                                       USER4_EMAIL]);
    }).spread((narrator, user1, user2, user3, user4) => {
        narratorUserId = narrator.id;
        userId1 = user1.id;
        userId2 = user2.id;
        userId3 = user3.id;
        userId4 = user4.id;
    });
});

test.beforeEach(t => {
    return store.createNarration({
        narratorId: narratorUserId,
        title: "Basic Test Narration",
        defaultAudio: DEFAULT_AUDIO,
        defaultBackgroundImage: DEFAULT_BACKGROUND
    }).then(narration => {
        t.context.testNarration = narration;

        return createCharacters(store,
                                [ [CHAR1_NAME, userId1, narration.id],
                                  [CHAR2_NAME, userId2, narration.id],
                                  [CHAR3_NAME, userId3, narration.id],
                                  [CHAR4_NAME, userId4, narration.id] ]);
    }).spread((char1, char2, char3, char4) => {
        t.context.characterId1 = char1.id;
        t.context.characterId2 = char2.id;
        t.context.characterId3 = char3.id;
        t.context.characterId4 = char4.id;
    });
});

const stash = {
    store: store,
    defaultBackground: DEFAULT_BACKGROUND,
    defaultAudio: DEFAULT_AUDIO,
    narratorEmail: NARRATOR_EMAIL,
    userEmail1: USER1_EMAIL,
    userEmail2: USER2_EMAIL,
    userEmail3: USER3_EMAIL,
    userEmail4: USER4_EMAIL,
    characterName1: CHAR1_NAME,
    characterName2: CHAR2_NAME,
    characterName3: CHAR3_NAME,
    characterName4: CHAR4_NAME
};
mailerTestcases(test, stash);
narrowsStoreTestcases(test, stash);

test.after.always(t => {
    fs.removeSync(TEST_FILES);
});
