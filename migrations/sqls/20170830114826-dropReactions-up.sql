INSERT INTO messages (chapter_id, sender_id, body)
SELECT
chapter_id, character_id, CONCAT('[Automatically imported action] ', main_text)
FROM reactions
WHERE main_text IS NOT NULL;

ALTER TABLE reactions DROP main_text;

RENAME TABLE reactions TO chapter_participants;
