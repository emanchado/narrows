UPDATE users SET email = CONCAT(username, '@example.com') WHERE email IS NULL;
ALTER TABLE users DROP username;
ALTER TABLE users MODIFY email varchar(128) UNIQUE AFTER id;
