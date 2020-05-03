CREATE TABLE narration_styles (
    narration_id integer NOT NULL UNIQUE,

    title_font varchar(64),
    title_font_size varchar(32),
    title_color varchar(32),
    title_shadow_color varchar(32),
    body_text_font varchar(64),
    body_text_font_size varchar(32),
    body_text_color varchar(32),
    body_text_background_color varchar(32),
    separator_image varchar(64),

    FOREIGN KEY (narration_id) REFERENCES narrations(id)
    ON DELETE CASCADE
);
