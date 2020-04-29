ALTER TABLE users ADD display_name VARCHAR(64) DEFAULT 'Anonymous Player' AFTER email;
UPDATE users SET display_name = CONCAT('User #', id);
