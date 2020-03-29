ALTER TABLE chapter_participants ADD CONSTRAINT chapter_participants_fk_chapter_id FOREIGN KEY (chapter_id) REFERENCES chapters (id) ON DELETE CASCADE;
ALTER TABLE chapter_participants ADD CONSTRAINT chapter_participants_fk_character_id FOREIGN KEY (character_id) REFERENCES characters (id) ON DELETE CASCADE;

ALTER TABLE password_reset_tokens DROP FOREIGN KEY password_reset_tokens_ibfk_1;
ALTER TABLE password_reset_tokens ADD CONSTRAINT password_reset_tokens_fk_user_id FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE;
