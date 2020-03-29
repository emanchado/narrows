ALTER TABLE chapter_participants DROP FOREIGN KEY chapter_participants_fk_chapter_id;
ALTER TABLE chapter_participants DROP FOREIGN KEY chapter_participants_fk_character_id;

ALTER TABLE password_reset_tokens DROP FOREIGN KEY password_reset_tokens_fk_user_id;
ALTER TABLE password_reset_tokens ADD CONSTRAINT password_reset_tokens_ibfk_1 FOREIGN KEY (user_id) REFERENCES users (id);
