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

test.serial("cannot create users without an email", t => {
    return t.context.store.createUser({
        role: "admin"
    }).then(newUser => {
        t.is(1, 0, "The createUser call should fail without an email");
    }).catch(err => {
        t.truthy(err);
    });
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
            t.is(user.id, userId)
        ))
    ));
});

test.serial("can create users with a given display name", t => {
    const email = "displayname@example.com", displayName = "hey yo whats up";

    return t.context.store.createUser({
        email: email,
        displayName: displayName
    }).then(newUser => {
        t.is(newUser.email, email);
        t.is(newUser.displayName, displayName);
    });
});

test.serial("users always have a display name", t => {
    const email = "default-displayname@example.com";

    return t.context.store.createUser({
        email: email
    }).then(newUser => {
        t.is(newUser.email, email);
        t.is(newUser.displayName, "User #" + newUser.id);
    });
});

test.serial("ignores spaces when creating users", t => {
    const email = "willaddspaces@example.com", password = "whatevs";

    return t.context.store.createUser({
        email: ` ${email}`,
        password: password
    }).then(user => (
        t.context.store.authenticate(email, password).then(userId => (
            t.is(user.id, userId)
        ))
    ));
});

test.serial("ignores spaces when searching for users", t => {
    const email = "ignore-space-search@example.com", password = "whatevs";

    return t.context.store.createUser({
        email: `             ${email}         `,
        password: password
    }).then(user => (
        t.context.store.getUserByEmail(` ${email}  `).then(foundUser => (
            t.is(user.id, foundUser.id)
        ))
    ));
});

test.serial("ignores case when searching for users", t => {
    const email = "ignore-case-search@example.com", password = "whatevs";

    return t.context.store.createUser({
        email: `             ${email}         `,
        password: password
    }).then(user => (
        t.context.store.getUserByEmail(email.toUpperCase()).then(foundUser => (
            t.is(user.id, foundUser.id)
        ))
    ));
});

test.serial("ignores spaces when authenticating users", t => {
    const email = "ignore-spaces-auth@example.com", password = "whatevs";

    return t.context.store.createUser({
        email: email,
        password: password
    }).then(user => (
        t.context.store.authenticate(` ${email}  `, password).then(userId => (
            t.is(user.id, userId)
        ))
    ));
});

test.serial("ignores spaces when authenticating users", t => {
    const email = "ignorecase-auth@example.com", password = "whatevs";

    return t.context.store.createUser({
        email: email,
        password: password
    }).then(user => (
        t.context.store.authenticate(` ${email}  `, password).then(userId => (
            t.is(user.id, userId)
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
                t.is(user.id, userId)
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
                t.is(user.id, userId)
            ))
        ))
    ));
});
