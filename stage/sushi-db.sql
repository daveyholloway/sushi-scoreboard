-- Create database and user
CREATE DATABASE sushi_tracker CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE USER 'sushi_user'@'localhost' IDENTIFIED BY 'supersecretsushipa55worD';
GRANT ALL PRIVILEGES ON sushi_tracker.* TO 'sushi_user'@'localhost';
FLUSH PRIVILEGES;

USE sushi_tracker;

-- Participants (people)
CREATE TABLE participants (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Sushi events (each visit)
CREATE TABLE events (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    event_date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Which participants attended which event
CREATE TABLE event_participants (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    event_id INT UNSIGNED NOT NULL,
    participant_id INT UNSIGNED NOT NULL,
    UNIQUE KEY uniq_event_participant (event_id, participant_id),
    CONSTRAINT fk_ep_event FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE,
    CONSTRAINT fk_ep_participant FOREIGN KEY (participant_id) REFERENCES participants(id) ON DELETE CASCADE
);

-- Plate colours (standing data)
CREATE TABLE plate_colours (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    display_order INT NOT NULL DEFAULT 0,
    hex_colour CHAR(7) NULL, -- e.g. #FF00AA
    active TINYINT(1) NOT NULL DEFAULT 1
);

-- Per-event price for each plate colour
CREATE TABLE event_plate_prices (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    event_id INT UNSIGNED NOT NULL,
    plate_colour_id INT UNSIGNED NOT NULL,
    unit_price DECIMAL(8,2) NOT NULL,
    UNIQUE KEY uniq_event_colour (event_id, plate_colour_id),
    CONSTRAINT fk_epp_event FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE,
    CONSTRAINT fk_epp_colour FOREIGN KEY (plate_colour_id) REFERENCES plate_colours(id) ON DELETE RESTRICT
);

-- Menu items (white plates with individual prices)
CREATE TABLE menu_items (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(150) NOT NULL UNIQUE,
    default_price DECIMAL(8,2) NULL,
    active TINYINT(1) NOT NULL DEFAULT 1
);

-- Per-event price override for menu items
CREATE TABLE event_menu_prices (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    event_id INT UNSIGNED NOT NULL,
    menu_item_id INT UNSIGNED NOT NULL,
    unit_price DECIMAL(8,2) NOT NULL,
    UNIQUE KEY uniq_event_menu (event_id, menu_item_id),
    CONSTRAINT fk_emp_event FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE,
    CONSTRAINT fk_emp_menu FOREIGN KEY (menu_item_id) REFERENCES menu_items(id) ON DELETE RESTRICT
);

-- Consumption of coloured plates (aggregated counts)
CREATE TABLE plate_consumption (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    event_id INT UNSIGNED NOT NULL,
    participant_id INT UNSIGNED NOT NULL,
    plate_colour_id INT UNSIGNED NOT NULL,
    quantity INT UNSIGNED NOT NULL DEFAULT 0,
    UNIQUE KEY uniq_plate_row (event_id, participant_id, plate_colour_id),
    CONSTRAINT fk_pc_event FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE,
    CONSTRAINT fk_pc_participant FOREIGN KEY (participant_id) REFERENCES participants(id) ON DELETE CASCADE,
    CONSTRAINT fk_pc_colour FOREIGN KEY (plate_colour_id) REFERENCES plate_colours(id) ON DELETE RESTRICT
);

-- Consumption of menu items (aggregated counts)
CREATE TABLE menu_consumption (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    event_id INT UNSIGNED NOT NULL,
    participant_id INT UNSIGNED NOT NULL,
    menu_item_id INT UNSIGNED NOT NULL,
    quantity INT UNSIGNED NOT NULL DEFAULT 0,
    UNIQUE KEY uniq_menu_row (event_id, participant_id, menu_item_id),
    CONSTRAINT fk_mc_event FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE,
    CONSTRAINT fk_mc_participant FOREIGN KEY (participant_id) REFERENCES participants(id) ON DELETE CASCADE,
    CONSTRAINT fk_mc_menu FOREIGN KEY (menu_item_id) REFERENCES menu_items(id) ON DELETE RESTRICT
);

-- Seed some standard plate colours (you can tweak names/order)
INSERT INTO plate_colours (name, display_order, hex_colour) VALUES
('Green', 10, '#00AA00'),
('Blue', 20, '#0077CC'),
('Purple', 30, '#800080'),
('Orange', 40, '#FF8800'),
('Pink', 50, '#FF66AA'),
('Grey', 60, '#888888'),
('Yellow', 70, '#FFDD00');

-- Optionally seed some menu items
INSERT INTO menu_items (name, default_price) VALUES
('Test Item 1', 1.00),
('Test Item 2', 2.00),
('test Item 3', 3.00);

CREATE TABLE default_prices (id INT AUTO_INCREMENT PRIMARY KEY, plate_colour VARCHAR(50) NOT NULL, price DECIMAL(5,2) NOT NULL) ;

INSERT INTO default_prices (plate_colour, price) VALUES ('Green',3.5), ('Blue',4.5),('Purple',5.5), ('Orange',6), ('Pink
',6.5), ('Grey',7.5), ('Yellow',8.5);
