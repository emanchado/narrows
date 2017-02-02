CREATE TABLE users (id integer AUTO_INCREMENT PRIMARY KEY,
                    username varchar(64) UNIQUE,
                    password varchar(128),
                    role varchar(64),
                    email text) DEFAULT CHARSET=utf8;
INSERT INTO users (username, password, role, email)
  VALUES ('narrator',
          '$2a$04$NrMPbG7wG26EwqJOun.SLOELYGOmbFs5aECGxhl8suPfVY049NZdG',
          'admin',
          'admin@example.com');
CREATE TABLE narrations (id integer AUTO_INCREMENT PRIMARY KEY,
                         narrator_id integer,
                         title varchar(256),
                         default_audio varchar(256),
                         default_background_image varchar(256),
                         FOREIGN KEY (narrator_id) REFERENCES users(id)
                         ON DELETE RESTRICT) DEFAULT CHARSET=utf8;
CREATE TABLE chapters (id integer AUTO_INCREMENT PRIMARY KEY,
                       narration_id integer,
                       title varchar(256),
                       audio varchar(256),
                       background_image varchar(256),
                       main_text text,
                       created timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
                       updated timestamp NOT NULL DEFAULT '2000-01-01',
                       published timestamp NULL,
                       FOREIGN KEY (narration_id) REFERENCES narrations(id)
                       ON DELETE RESTRICT) DEFAULT CHARSET=utf8;
CREATE TABLE characters (id integer AUTO_INCREMENT PRIMARY KEY,
                         narration_id integer,
                         player_id integer,
                         name varchar(256),
                         token varchar(128),
                         avatar varchar(256),
                         description text,
                         backstory text,
                         notes text,
                         FOREIGN KEY (narration_id) REFERENCES narrations(id)
                         ON DELETE RESTRICT,
                         FOREIGN KEY (player_id) REFERENCES users(id)
                         ON DELETE RESTRICT) DEFAULT CHARSET=utf8;
CREATE TABLE reactions (id integer AUTO_INCREMENT PRIMARY KEY,
                        chapter_id integer references chapters(id) ON DELETE CASCADE,
                        character_id integer references characters(id) ON DELETE CASCADE,
                        main_text text) DEFAULT CHARSET=utf8;
CREATE TABLE messages (id integer AUTO_INCREMENT PRIMARY KEY,
                       chapter_id integer,
                       sender_id integer,
                       body text,
                       sent timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
                       FOREIGN KEY (chapter_id) REFERENCES chapters(id)
                       ON DELETE RESTRICT,
                       FOREIGN KEY (sender_id) REFERENCES characters(id)
                       ON DELETE RESTRICT) DEFAULT CHARSET=utf8;
CREATE TABLE message_deliveries (message_id integer,
                                 recipient_id integer,
                                 FOREIGN KEY (message_id) REFERENCES messages(id)
                                 ON DELETE CASCADE,
                                 FOREIGN KEY (recipient_id) REFERENCES characters(id)
                                 ON DELETE CASCADE) DEFAULT CHARSET=utf8;
