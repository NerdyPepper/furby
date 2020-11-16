-- Your SQL goes here
CREATE TABLE product (
    id INTEGER PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    kind VARCHAR(255),
    price FLOAT NOT NULL,
    description VARCHAR(255)
)
