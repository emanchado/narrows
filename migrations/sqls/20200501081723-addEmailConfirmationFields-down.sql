ALTER TABLE users DROP verified, DROP created;

DELETE FROM user_tokens WHERE token_type <> 'password_reset';
ALTER TABLE user_tokens DROP token_type;
RENAME TABLE user_tokens TO password_reset_tokens;
