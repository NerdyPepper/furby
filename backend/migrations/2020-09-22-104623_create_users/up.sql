-- Your SQL goes here
CREATE TABLE members (
    id INTEGER PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    phone_number VARCHAR(10) NOT NULL,
    email_id VARCHAR(255) NOT NULL
)
