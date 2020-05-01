ALTER TABLE users ADD verified boolean DEFAULT FALSE, ADD created timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP;
UPDATE users SET verified = TRUE;

ALTER TABLE password_reset_tokens ADD token_type varchar(32);
UPDATE password_reset_tokens SET token_type = 'password_reset';
RENAME TABLE password_reset_tokens TO user_tokens;
