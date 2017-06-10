CREATE TABLE password_reset_tokens (id integer AUTO_INCREMENT PRIMARY KEY,
                                    user_id integer NOT NULL,
                                    token varchar(128) NOT NULL,
                                    created timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                    FOREIGN KEY (user_id) REFERENCES users(id)) DEFAULT CHARSET=utf8;
