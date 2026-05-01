-- TODO
-- In the consumption tables, menu_item_id and plate_id should be 
-- event_menu_item_id and event_plate_id

-- Create database and user
CREATE DATABASE sushi_scoreboard CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE USER 'sushi_user'@'localhost' IDENTIFIED BY 'supersecretsushipa55worD';
GRANT ALL PRIVILEGES ON sushi_scoreboard.* TO 'sushi_user'@'localhost';
FLUSH PRIVILEGES;

USE sushi_scoreboard ;

-- Drop the tables if they already exist
DROP TABLE IF EXISTS event_plate_consumption ;
DROP TABLE IF EXISTS event_menu_consumption ;

DROP TABLE IF EXISTS event_participant ;
DROP TABLE IF EXISTS event_plate ;
DROP TABLE IF EXISTS event_menu_item ;

DROP TABLE IF EXISTS participant ;
DROP TABLE IF EXISTS event ;
DROP TABLE IF EXISTS plate ;
DROP TABLE IF EXISTS menu_item ;

-- The participant table, holds a master list of all possible
-- participants.
CREATE TABLE participant (
    id             INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name           VARCHAR(100) NOT NULL UNIQUE,
    tstamp_created TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Add some sample participants
INSERT INTO participant (name) VALUES
('Tom') ,
('Dick') ,
('Harry') ;

-- The event table, a row is created for every sushi event.
CREATE TABLE event (
    id             INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name           VARCHAR(150) NOT NULL,
    event_date     DATE NOT NULL,
    tstamp_created TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Associate participants with an event, this gives us the many to many 
-- relationship
CREATE TABLE event_participant (
    id             INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    event_id       INT UNSIGNED NOT NULL,
    participant_id INT UNSIGNED NOT NULL,
    UNIQUE KEY uniq_event_participant (event_id, participant_id),
    CONSTRAINT fk_ep_event FOREIGN KEY (event_id) REFERENCES event(id) ON DELETE CASCADE,
    CONSTRAINT fk_ep_participant FOREIGN KEY (participant_id) REFERENCES participant(id) ON DELETE CASCADE
);

-- The list of coloured plates and default prices
CREATE TABLE plate (
    id             INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name           VARCHAR(50) NOT NULL UNIQUE,
    hex_colour     CHAR(7) NULL, -- e.g. #FF00AA
    price          DECIMAL(5,2) NOT NULL,
    tstamp_created TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Add some standing data for starters
INSERT INTO plate (name, price, hex_colour) VALUES
('Green'  , 3.50, '#00AA00'),
('Blue'   , 4.50, '#0077CC'),
('Purple' , 5.50, '#800080'),
('Orange' , 6.00, '#FF8800'),
('Pink'   , 6.50, '#FF66AA'),
('Grey'   , 7.50, '#888888'),
('Yellow' , 8.50, '#FFDD00');

-- Plate prices may vary between events so list those here
CREATE TABLE event_plate (
    id             INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    event_id       INT UNSIGNED NOT NULL,
    plate_id       INT UNSIGNED NOT NULL,
    price          DECIMAL(5,2) NOT NULL,
    UNIQUE KEY uniq_event_plate (event_id, plate_id),
    CONSTRAINT fk_epp_event FOREIGN KEY (event_id) REFERENCES event(id) ON DELETE CASCADE,
    CONSTRAINT fk_epp_plate FOREIGN KEY (plate_id) REFERENCES plate(id) ON DELETE RESTRICT
);

-- Sometimes, regular menu items are also included so stick those here:
CREATE TABLE menu_item (
    id             INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name           VARCHAR(150) NOT NULL UNIQUE,
    price          DECIMAL(5,2) NULL,
    tstamp_created TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Add some standing data for starters
INSERT INTO menu_item (name, price) VALUES
('Vegetable Goyoza'      , 6.95),
('Chicken Goyoza'        , 7.50),
('Chicken Katsu'         , 6.95);

-- Menu prices may vary between events so list those here
CREATE TABLE event_menu_item (
    id             INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    event_id       INT UNSIGNED NOT NULL,
    menu_item_id   INT UNSIGNED NOT NULL,
    price          DECIMAL(5,2) NOT NULL,
    UNIQUE KEY uniq_event_menu_item (event_id, menu_item_id),
    CONSTRAINT fk_emi_event FOREIGN KEY (event_id)     REFERENCES event(id) ON DELETE CASCADE,
    CONSTRAINT fk_emi_menu  FOREIGN KEY (menu_item_id) REFERENCES menu_item(id) ON DELETE RESTRICT
);

-- Store consumption of coloured plates
CREATE TABLE event_plate_consumption (
    id             INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    event_id       INT UNSIGNED NOT NULL,
    participant_id INT UNSIGNED NOT NULL,
    plate_id       INT UNSIGNED NOT NULL,
    quantity       INT UNSIGNED NOT NULL DEFAULT 0,
    UNIQUE KEY uniq_plate_row (event_id, participant_id, plate_id),
    CONSTRAINT fk_pc_event       FOREIGN KEY (event_id)       REFERENCES event(id) ON DELETE CASCADE,
    CONSTRAINT fk_pc_participant FOREIGN KEY (participant_id) REFERENCES participant(id) ON DELETE CASCADE,
    CONSTRAINT fk_pc_plate       FOREIGN KEY (plate_id)       REFERENCES event_plate(id) ON DELETE RESTRICT
);

-- Store consumption of menu items 
CREATE TABLE event_menu_consumption (
    id             INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    event_id       INT UNSIGNED NOT NULL,
    participant_id INT UNSIGNED NOT NULL,
    menu_item_id   INT UNSIGNED NOT NULL,
    quantity       INT UNSIGNED NOT NULL DEFAULT 0,
    UNIQUE KEY uniq_menu_row (event_id, participant_id, menu_item_id),
    CONSTRAINT fk_mc_event       FOREIGN KEY (event_id)       REFERENCES event(id) ON DELETE CASCADE,
    CONSTRAINT fk_mc_participant FOREIGN KEY (participant_id) REFERENCES participant(id) ON DELETE CASCADE,
    CONSTRAINT fk_mc_menu        FOREIGN KEY (menu_item_id)   REFERENCES event_menu_item(id) ON DELETE RESTRICT
);
