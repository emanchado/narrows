RENAME TABLE chapter_participants TO reactions;

ALTER TABLE reactions ADD main_text text;

UPDATE reactions
SET main_text = (
    SELECT REPLACE(body, '[Automatically imported action] ', '')
      FROM messages
     WHERE body LIKE '[Automatically imported action] %'
       AND messages.chapter_id = reactions.chapter_id
       AND messages.sender_id = reactions.character_id
);

DELETE FROM messages WHERE body LIKE '[Automatically imported action] %';
