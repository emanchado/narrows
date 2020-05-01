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

const ONE_WEEK = 7 * 24 * 60 * 60;

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

test.serial("can create users already verified", t => {
    const email = "verified@example.com";

    return t.context.store.createUser({
        email: email,
        verified: true
    }).then(newUser => {
        t.is(newUser.email, email);
        t.is(newUser.verified, true);
    });
});

test.serial("can verify user email addresses", t => {
    const email = "toverify@example.com";

    return t.context.store.createUser({
        email: email
    }).then(user => (
        t.context.store.createEmailVerificationToken(user.id)
    )).then(token => (
        t.context.store.verifyEmail(token)
    )).then(() => (
        t.context.store.getUserByEmail(email)
    )).then(updatedUser => {
        t.is(updatedUser.verified, 1);
    });
});

test.serial("cannot use random tokens to verify user email addresses", t => {
    const email = "toverify@example.com";

    return t.context.store.createUser({
        email: email
    }).then(user => (
        t.context.store.verifyEmail("abcdef")
    )).then(() => {
        t.truthy(false, "verifyEmail should fail for random tokens");
    }).catch(err => {
        t.truthy(true, "verifyEmail should fail for random tokens");
    });
});

test.serial("cannot verify a user twice", t => {
    const email = "toverify@example.com";

    return t.context.store.createUser({
        email: email
    }).then(user => (
        t.context.store.createEmailVerificationToken(user.id)
    )).then(token => (
        t.context.store.verifyEmail(token)
    )).then(token => (
        t.context.store.verifyEmail(token)  // Second time fails
    )).then(() => {
        t.truthy(false, "The second verifyEmail should fail!");
    }).catch(err => {
        t.truthy(true, "The second verifyEmail should fail");
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

test.serial("users can be deleted", t => {
    const email = "delete@example.com";

    return t.context.store.createUser({
        email: email
    }).then(user => (
        t.context.store.deleteUser(user.id)
    )).then(() => (
        t.context.store.getUserByEmail(email).then(foundUser => {
            return true;
        }).catch(err => {
            return false;
        })
    )).then(found => {
        t.is(found, false, "Users should be there after deleting");
    });
});

test.serial("old unverified users get cleaned up", t => {
    const email = "oldunverified@example.com";
    const email2 = "oldunverified2@example.com";
    const justOverAWeekOld = new Date();
    justOverAWeekOld.setDate(justOverAWeekOld.getDate() - 8);

    return Q.all([
        t.context.store.createUser({email: email, created: '2020-04-01'}),
        t.context.store.createUser({email: email2, created: justOverAWeekOld})
    ]).then(() => {
        return t.context.store.deleteOldUnverifiedUsers(ONE_WEEK);
    }).then(() => (
        t.context.store.getUserByEmail(email).then(foundUser => {
            return true;
        }).catch(err => {
            return false;
        })
    )).then(found => {
        t.is(found, false, "Old, unverified users should be deleted");
    });
});

test.serial("not old enough, unverified users stay", t => {
    const email = "notsooldunverified@example.com";
    const almostAWeekOld = new Date();
    almostAWeekOld.setDate(almostAWeekOld.getDate() - 6);

    return t.context.store.createUser({email: email, created: almostAWeekOld}).then(() => {
        return t.context.store.deleteOldUnverifiedUsers(ONE_WEEK);
    }).then(() => (
        t.context.store.getUserByEmail(email).then(foundUser => {
            return true;
        }).catch(err => {
            return false;
        })
    )).then(found => {
        t.is(found, true, "Not so old, unverified users should stay");
    });
});
