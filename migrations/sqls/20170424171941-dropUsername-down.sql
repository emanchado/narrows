ALTER TABLE users ADD username varchar(64);
UPDATE users SET username = email;
ALTER TABLE users MODIFY username varchar(64) UNIQUE AFTER id;
