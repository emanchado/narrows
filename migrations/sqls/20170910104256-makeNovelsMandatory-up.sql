ALTER TABLE characters ADD novel_token varchar(128) AFTER token;

UPDATE characters
SET novel_token = (
    SELECT token
      FROM narration_exports
     WHERE narration_exports.character_id = characters.id
);

UPDATE characters
   SET novel_token = UUID()
 WHERE novel_token IS NULL;

DROP TABLE narration_exports;
