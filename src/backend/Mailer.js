import fs from "fs";
import path from "path";
import config from "config";
import ejs from "ejs";
import Q from "q";

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

    sendMail(template, recipient, subject, stash) {
        if (!recipient) {
            // Nothing to do
            return;
        }

        const textTemplate = path.join(config.mail.templateDir, `${template}.txt.ejs`);
        const htmlTemplate = path.join(config.mail.templateDir, `${template}.html.ejs`);
        const text = ejs.render(fs.readFileSync(textTemplate, "utf-8"), stash);
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
            this.store.getCharacterEmails(participants.map(p => p.id))
        ]).spread((narration, emails) => {
            participants.forEach(participant => {
                this.sendMail(
                    "chapterPublished",
                    emails[participant.id],
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
            this.store.getCharacterEmails(message.recipients)
        ]).spread((chapter, emails) => {
            message.recipients.forEach(recipient => {
                this.store.getCharacterTokenById(recipient).then(token => (
                    this.sendMail(
                        "messagePosted",
                        emails[recipient],
                        `New message in "${chapter.title}"`,
                        {senderName: message.sender.name,
                         messageText: message.text,
                         chapterTitle: chapter.title,
                         chapterUrl: this.chapterUrlFor(chapter.id, token)}
                    ).catch(console.error)
                ));
            });

            // If this was sent by a player, send a copy to the narrator
            if (message.sender.id) {
                this.store.getNarratorEmail(chapter.narrationId).then(email => (
                    this.sendMail(
                        "messagePosted",
                        email,
                        `New message in "${chapter.title}"`,
                        {senderName: message.sender.name,
                         messageText: message.text,
                         chapterTitle: chapter.title,
                         chapterUrl: this.chapterNarratorUrlFor(chapter.id)}
                    ).catch(console.error)
                ));
            }
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
            ]).spread((narration, narratorEmail) => {
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
                ).catch(console.error);
            });
        }).catch(console.error);
    }
};

module.exports = Mailer;
