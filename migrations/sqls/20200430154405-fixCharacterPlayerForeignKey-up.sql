ALTER TABLE characters DROP FOREIGN KEY characters_ibfk_2;
ALTER TABLE characters ADD CONSTRAINT characters_ibfk_2 FOREIGN KEY (player_id) REFERENCES users(id) ON DELETE SET NULL;
