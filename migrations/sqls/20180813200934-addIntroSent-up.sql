ALTER TABLE characters ADD intro_sent timestamp NULL DEFAULT NULL;
UPDATE characters SET intro_sent = NOW();
