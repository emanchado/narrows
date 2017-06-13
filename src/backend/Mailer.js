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

    chapterUrlFor(chapterId, characterToken) {
        return `${config.publicAddress}/read/${chapterId}/${characterToken}`;
    }

    chapterNarratorUrlFor(chapterId) {
        return `${config.publicAddress}/chapters/${chapterId}`;
    }

    passwordResetLink(passwordResetToken) {
        return `${config.publicAddress}/password-reset/${passwordResetToken}`;
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
                this.sendMail(
                    "chapterPublished",
                    info[participant.id].email,
                    `New chapter published: "${chapter.title}"`,
                    {narrationTitle: narration.title,
                     chapterTitle: chapter.title,
                     chapterUrl: this.chapterUrlFor(chapter.id, participant.token)}
                );
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
                        info[recipientId].email,
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

    reactionPosted(chapterId, characterToken, reactionText) {
        return Q.all([
            this.store.getChapter(chapterId),
            this.store.getCharacterInfo(characterToken)
        ]).spread((chapter, character) => {
            return Q.all([
                this.store.getNarration(chapter.narrationId),
                this.store.getNarratorEmail(chapter.narrationId)
            ]).spread((narration, narratorEmail) => (
                this.sendMail(
                    "reactionPosted",
                    narratorEmail,
                    `${character.name} reacted to` +
                        ` "${chapter.title}" in "${narration.title}"`,
                    {characterName: character.name,
                     reactionText: reactionText,
                     chapterTitle: chapter.title,
                     narrationTitle: narration.title,
                     chapterUrl: this.chapterNarratorUrlFor(chapter.id)}
                )
            ));
        }).catch(console.error);
    }

    passwordReset(email, passwordResetToken) {
        this.sendMail(
            "passwordReset",
            email,
            `NARROWS password reset`,
            {email: email,
             passwordResetLink: this.passwordResetLink(passwordResetToken)}
        );
    }
};

module.exports = Mailer;
