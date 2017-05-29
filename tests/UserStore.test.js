import config from "config";
import test from "ava";
import Q from "q";
import { recreateDb } from "./test-utils.js";
import UserStore from "../src/backend/UserStore";

const userTestsDb = Object.assign(
    {},
    config.db,
    { database: "narrows-userstore-test" }
);

// Because recreating the database is heavy, we do it only once for
// all tests
test.before(t => recreateDb(userTestsDb));

test.beforeEach(t => {
    t.context.store = new UserStore(userTestsDb);
    t.context.store.connect();
});

test.serial("can create users with a given role", t => {
    return t.context.store.createUser({
        email: "role@example.com",
        role: "admin"
    }).then(newUser => {
        t.is(newUser.email, "role@example.com");
        t.is(newUser.role, "admin");
    });
});

test.serial("can create users with a given password", t => {
    const email = "pass@example.com", password = "hey yo whats up";

    return t.context.store.createUser({
        email: email,
        password: password
    }).then(user => (
        t.context.store.authenticate(email, password).then(userId => (
            t.truthy(user.id, userId)
        ))
    ));
});

test.serial("can change a user's password", t => {
    const email = "passchange@example.com", password = "original or remake";

    return t.context.store.createUser({
        email: email,
        password: password
    }).then(user => (
        t.context.store.updateUser(user.id, { password: "foo" }).then(() => (
            t.context.store.authenticate(email, "foo").then(userId => (
                t.truthy(user.id, userId)
            ))
        ))
    ));
});

test.serial("setting empty password doesn't change it", t => {
    const email = "pass-stay@example.com", password = "original or remake";

    return t.context.store.createUser({
        email: email,
        password: password
    }).then(user => (
        t.context.store.updateUser(user.id, { password: "" }).then(() => (
            t.context.store.authenticate(email, password).then(userId => (
                t.truthy(user.id, userId)
            ))
        ))
    ));
});
