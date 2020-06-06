import fs from "fs";
import path from "path";
import config from "config";
import ejs from "ejs";
import Q from "q";

function humanReadableList(list) {
    if (list.length < 2) {
        return list[0];
    }

    if (list.length === 2) {
        return `${list[0]} and ${list[1]}`;
    }

    const allButLast = list.slice(0, list.length - 1);
    return allButLast.join(", ") + ", and " + list[list.length - 1];
}

class Mailer {
    constructor(store, transport) {
        this.store = store;
        this.transport = transport;
    }

    narrationUrlFor(narrationId) {
        return `${config.publicAddress}/narrations/${narrationId}`;
    }

    chapterUrlFor(chapterId, characterToken) {
        return `${config.publicAddress}/read/${chapterId}/${characterToken}`;
    }

    chapterNarratorUrlFor(chapterId) {
        return `${config.publicAddress}/chapters/${chapterId}`;
    }

    characterUrlFor(characterToken) {
        return `${config.publicAddress}/characters/${characterToken}`;
    }

    passwordResetLink(passwordResetToken) {
        return `${config.publicAddress}/password-reset/${passwordResetToken}`;
    }

    emailVerificationLink(emailVerificationToken) {
        return `${config.publicAddress}/email-verification/${emailVerificationToken}`;
    }

    sendMail(template, givenRecipient, subject, stash) {
        if (!givenRecipient) {
            // Nothing to do
            return;
        }

        const recipient = config.mail.alwaysSendTo || givenRecipient;
        const textTemplate = path.join(config.mail.templateDir, `${template}.txt.ejs`);
        const htmlTemplate = path.join(config.mail.templateDir, `${template}.html.ejs`);
        // Don't escape plain text
        const text = ejs.render(fs.readFileSync(textTemplate, "utf-8"),
                                stash,
                                { escape: text => text });
        const html = ejs.render(fs.readFileSync(htmlTemplate, "utf-8"), stash);

        const mailOptions = {
            from: config.mail.from,
            to: recipient,
            subject: subject,
            text: text,
            html: html
        };

        this.transport.sendMail(mailOptions, function(error, info) {
            if (error) {
                console.error("Error in sendMail:", error);
            }
        });
    }

    chapterPublished(chapter) {
        const participants = chapter.participants;

        return Q.all([
            this.store.getNarration(chapter.narrationId),
            this.store.getCharacterInfoBulk(participants.map(p => p.id))
        ]).spread((narration, info) => {
            participants.forEach(participant => {
                if (info[participant.id]) {
                    this.sendMail(
                        "chapterPublished",
                        info[participant.id].email,
                        `New chapter published: "${chapter.title}"`,
                        {narrationTitle: narration.title,
                         chapterTitle: chapter.title,
                         chapterUrl: this.chapterUrlFor(chapter.id,
                                                        participant.token)}
                    );
                }
            });
        }).catch(console.error);
    }

    messagePosted(message) {
        return Q.all([
            this.store.getChapter(message.chapterId),
            this.store.getCharacterInfoBulk(message.recipients)
        ]).spread((chapter, info) => {
            const promises = message.recipients.map(recipientId => {
                const otherRecipientIds = Object.keys(info).filter(
                    id => parseInt(id, 10) !== recipientId
                );
                let baseRecipients =
                      otherRecipientIds.map(id => info[id].name);
                if (message.sender.id) {
                    baseRecipients = baseRecipients.concat("the narrator");
                }
                const recipients =
                      humanReadableList(baseRecipients.concat("you"));

                return this.store.getCharacterTokenById(recipientId).then(token => (
                    this.sendMail(
                        "messagePosted",
                        info[recipientId] && info[recipientId].email,
                        `${message.sender.name} sent a message in "${chapter.title}"`,
                        {senderName: message.sender.name,
                         recipientListString: recipients,
                         messageText: message.text,
                         chapterTitle: chapter.title,
                         chapterUrl: this.chapterUrlFor(chapter.id, token)}
                    )
                ));
            });

            // If this was sent by a player, send a copy to the narrator
            if (message.sender.id) {
                const recipientNames =
                      Object.keys(info).map(id => info[id].name);
                const recipients =
                      humanReadableList(recipientNames.concat("you"));

                promises.push(this.store.getNarratorEmail(chapter.narrationId).then(email => (
                    this.sendMail(
                        "messagePosted",
                        email,
                        `${message.sender.name} sent a message in "${chapter.title}"`,
                        {senderName: message.sender.name,
                         recipientListString: recipients,
                         messageText: message.text,
                         chapterTitle: chapter.title,
                         chapterUrl: this.chapterNarratorUrlFor(chapter.id)}
                    )
                )));
            }

            return Q.all(promises);
        }).catch(console.error);
    }

    passwordReset(email, passwordResetToken) {
        this.sendMail(
            "passwordReset",
            email,
            'NARROWS password reset',
            {email: email,
             passwordResetLink: this.passwordResetLink(passwordResetToken)}
        );
    }

    characterClaimed(email, narration, claimedCharacter) {
        // Send the user an intro message
        this.sendMail(
            "characterClaimed",
            email,
            `Your character ${claimedCharacter.name} for "${narration.title}" in NARROWS`,
            {narrationTitle: narration.title,
             characterName: claimedCharacter.name,
             characterSheetLink: this.characterUrlFor(claimedCharacter.token)}
        );

        Q.all([
            this.store.getNarratorEmail(narration.id),
            this.store.getCharacterInfoBulk(narration.characters.map(c => c.id))
        ]).spread((narratorEmail, charactersWithEmailHash) => {
            // Object.values might not be available, so do it by hand
            const charactersWithEmail =
                  Object.keys(charactersWithEmailHash).map(
                      id => charactersWithEmailHash[id]
                  );

            // Calculate the number of unclaimed characters
            const numberUnclaimed = charactersWithEmail.filter(
                c => c.email === null
            ).length;

            // Tell the narrator a character was claimed
            this.sendMail(
                "characterClaimedNarrator",
                narratorEmail,
                `${claimedCharacter.name} was claimed in "${narration.title}"`,
                {narrationTitle: narration.title,
                 characterName: claimedCharacter.name,
                 characterSheetLink: this.characterUrlFor(claimedCharacter.token),
                 narrationLink: this.narrationUrlFor(narration.id),
                 numberUnclaimed: numberUnclaimed}
            );

            // Tell the other players that a character was claimed
            charactersWithEmail.forEach(character => {
                if (character.email && character.email !== email) {
                    this.sendMail(
                        "characterClaimedFellowPlayer",
                        character.email,
                        `${claimedCharacter.name} was claimed in "${narration.title}"`,
                        {narrationTitle: narration.title,
                         characterName: claimedCharacter.name,
                         narrationLink: narration.introUrl,
                         numberUnclaimed: numberUnclaimed}
                    );
                }
            });
        }).catch(err => {
            console.error("Error sending character claim emails -", err);
        });
    }

    characterUnclaimed(narration, character) {
        this.store.getNarratorEmail(narration.id).then(narratorEmail => {
            this.sendMail(
                "characterUnclaimed",
                narratorEmail,
                `${character.name} was abandoned in "${narration.title}"`,
                {narrationTitle: narration.title,
                 characterName: character.name,
                 characterSheetLink: this.characterUrlFor(character.token),
                 narrationLink: narration.introUrl}
            );
        });
    }

    emailVerification(email, token) {
        this.sendMail(
            "emailVerification",
            email,
            'NARROWS email verification',
            {emailVerificationUrl: this.emailVerificationLink(token)}
        );
    }
};

module.exports = Mailer;
