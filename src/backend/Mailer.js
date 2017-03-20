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
            message.recipients.forEach(recipientId => {
                const otherRecipientIds = Object.keys(info).filter(
                    id => parseInt(id, 10) !== recipientId
                );
                const baseRecipients =
                      otherRecipientIds.map(id => info[id].name).join(", ");
                const recipients =
                      baseRecipients + (otherRecipientIds.length ?
                                        ", the narrator, and you" :
                                        "the narrator and you");

                this.store.getCharacterTokenById(recipientId).then(token => (
                    this.sendMail(
                        "messagePosted",
                        info[recipientId].email,
                        `New message in "${chapter.title}"`,
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
                const baseRecipients =
                      Object.keys(info).map(id => info[id].name).join(", ");
                const recipients =
                      baseRecipients + (Object.keys(info).length > 1 ?
                                        ", and you" : " and you");

                this.store.getNarratorEmail(chapter.narrationId).then(email => (
                    this.sendMail(
                        "messagePosted",
                        email,
                        `New message in "${chapter.title}"`,
                        {senderName: message.sender.name,
                         recipientListString: recipients,
                         messageText: message.text,
                         chapterTitle: chapter.title,
                         chapterUrl: this.chapterNarratorUrlFor(chapter.id)}
                    )
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
};

module.exports = Mailer;
