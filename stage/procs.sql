USE sushi_scoreboard;

DELIMITER $$

-- Drop everything first (if it exists)
DROP PROCEDURE IF EXISTS sp_list_events;
DROP PROCEDURE IF EXISTS sp_create_event;
DROP PROCEDURE IF EXISTS sp_delete_event;
DROP PROCEDURE IF EXISTS sp_edit_event;

DROP PROCEDURE IF EXISTS sp_list_participants;
DROP PROCEDURE IF EXISTS sp_create_participant ;
DROP PROCEDURE IF EXISTS sp_delete_participant ;
DROP PROCEDURE IF EXISTS sp_edit_participant ;

DROP PROCEDURE IF EXISTS sp_list_plates ;

DROP PROCEDURE IF EXISTS sp_list_menu_items ;
DROP PROCEDURE IF EXISTS sp_create_menu_item ;

DROP PROCEDURE IF EXISTS sp_add_participant_by_id;
DROP PROCEDURE IF EXISTS sp_add_participant_by_name;

DROP PROCEDURE IF EXISTS sp_list_event_participants ;
DROP PROCEDURE IF EXISTS sp_add_event_participant_by_id ;
DROP PROCEDURE IF EXISTS sp_remove_event_participant_by_id ;

DROP PROCEDURE IF EXISTS sp_update_event_participant_plate_count ;

-- ############################################################################
-- Stored procedures related to:
-- █████                 ██      ██            ██                         ██
-- ██  ██                ██                                               ██
-- ██  ██  ████  ██ ██  █████   ███    ████   ███   █████   ████  █████  █████
-- █████      ██ ███ ██  ██      ██   ██  ██   ██   ██  ██     ██ ██  ██  ██
-- ██      █████ ██      ██      ██   ██       ██   ██  ██  █████ ██  ██  ██
-- ██     ██  ██ ██      ██      ██   ██  ██   ██   █████  ██  ██ ██  ██  ██
-- ██      █████ ██       ███   ████   ████   ████  ██      █████ ██  ██   ███
--                                                  ██
-- ############################################################################

-- ****************************************************************************
-- List all currently recorded participants
-- ========================================
--
-- Returns a result set of all the participants in the database.
-- ****************************************************************************
CREATE PROCEDURE sp_list_participants()
BEGIN
    SELECT id, name
    FROM participant
    ORDER BY id DESC ;
END $$

-- ****************************************************************************
-- Create a new Participant
-- ========================
--
-- Adds a new participant to the database.
-- ****************************************************************************
CREATE PROCEDURE sp_create_participant(
    IN p_name VARCHAR(100)
)
BEGIN
    DECLARE exit HANDLER FOR 1062
    BEGIN
        SELECT 0 AS ok, CONCAT(
            'Participant "', p_name,
            '" already exists.'
        ) AS outcome;
    END;

    INSERT INTO participant (name)
    VALUES (p_name);

    SELECT 1 AS ok, CONCAT(
        'Participant "', p_name,
        '" created successfully.'
    ) AS outcome;
END $$

-- ****************************************************************************
-- Edit an participant
-- ===================
--
-- Pass in a Participant ID and update the name to the value provided.
-- ****************************************************************************
CREATE PROCEDURE sp_edit_participant(
    IN p_participant_id   INT(10),
    IN p_name             VARCHAR(100)
)
BEGIN
    DECLARE exit HANDLER FOR 1062
    BEGIN
        SELECT 0 AS ok, CONCAT(
            'Participant "', p_name,
            '" already exists.'
        ) AS outcome;
    END;

    UPDATE participant
       SET name = p_name
     WHERE id = p_participant_id ;

    IF ROW_COUNT() = 0 THEN
        SELECT 0 AS ok, CONCAT(
            'Participant ', p_participant_id,
            ' does not exist.'
        ) AS outcome;
    ELSE
        SELECT 1 AS ok, CONCAT(
            'Participant ', p_participant_id,
            ' updated successfully.'
        ) AS outcome;
    END IF;
END $$

-- ############################################################################
-- Stored procedures related to:
-- █████   ███           ██
-- ██  ██   ██           ██
-- ██  ██   ██    ████  █████   ████
-- █████    ██       ██  ██    ██  ██
-- ██       ██    █████  ██    ██████
-- ██       ██   ██  ██  ██    ██
-- ██      ████   █████   ███   ████
-- ############################################################################

-- ****************************************************************************
-- List all Plates
-- ===============
--
-- Returns a result set of all plates in the database.
-- ****************************************************************************
CREATE PROCEDURE sp_list_plates()
BEGIN
    SELECT id, name, hex_colour, price
    FROM plate
    ORDER BY id ;
END $$

-- ############################################################################
-- Stored procedures related to:
-- ██   █                             ██████  ██
-- ███ ██                               ██    ██
-- ██████  ████  █████  ██  ██          ██   █████   ████   ██ ██
-- ██ █ █ ██  ██ ██  ██ ██  ██          ██    ██    ██  ██ ██████
-- ██ █ █ ██████ ██  ██ ██  ██          ██    ██    ██████ ██ █ █
-- ██   █ ██     ██  ██ ██  ██          ██    ██    ██     ██ █ █
-- ██   █  ████  ██  ██  █████        ██████   ███   ████  ██   █
-- ############################################################################

-- ****************************************************************************
-- List all Menu Items
-- ===================
--
-- Returns a result set of all the menu items in the database.
-- ****************************************************************************
CREATE PROCEDURE sp_list_menu_items()
BEGIN
    SELECT id, name, price
    FROM menu_item
    ORDER BY id ;
END $$

-- ****************************************************************************
-- Create a new Menu Item  
-- ======================
--
-- Adds a new menu item to the database.
-- ****************************************************************************
CREATE PROCEDURE sp_create_menu_item(
    IN p_name   VARCHAR(150),
    IN p_price  DECIMAL(5,2) 
)
BEGIN
    DECLARE exit HANDLER FOR 1062
    BEGIN
        SELECT 0 AS ok, CONCAT(
            'Menu item "', p_name,
            '" already exists.'
        ) AS outcome;
    END;

    INSERT INTO menu_item (name, price)
    VALUES (p_name, p_price);

    SELECT 1 AS ok, CONCAT(
        'Menu item "', p_name,
        '" created successfully.'
    ) AS outcome;
END $$

-- ############################################################################
-- Stored procedures related to:
-- ██████                       ██
-- ██                           ██
-- ██     ██  ██  ████  █████  █████
-- █████  ██  ██ ██  ██ ██  ██  ██
-- ██     ██  ██ ██████ ██  ██  ██
-- ██      ████  ██     ██  ██  ██
-- ██████   ██    ████  ██  ██   ███
-- ############################################################################

-- ****************************************************************************
-- List Events
-- ===========
--
-- Returns a result set of all the events in the database.
-- ****************************************************************************
CREATE PROCEDURE sp_list_events()
BEGIN
    SELECT id, name, event_date
    FROM event
    ORDER BY event_date DESC ;
END $$

-- ****************************************************************************
-- Create an Event
-- ===============
--
-- Adds a new even with the given name and date, returns a result set
-- containing a success flag and status message.
-- New event id is returned via an OUT parameter.
-- ****************************************************************************
CREATE PROCEDURE sp_create_event(
    IN p_name VARCHAR(150),
    IN p_event_date DATE,
    OUT p_event_id INT
)
BEGIN
    DECLARE exit HANDLER FOR 1062
    BEGIN
        SET p_event_id = NULL;
        SELECT 0 AS ok,
               CONCAT('Event with name "', p_name, '" already exists.') AS outcome,
               NULL AS event_id;
    END;

    INSERT INTO event (name, event_date)
    VALUES (p_name, p_event_date);

    SET p_event_id = LAST_INSERT_ID();

    SELECT 1 AS ok,
           CONCAT('Event "', p_name, '" created successfully.') AS outcome,
           p_event_id AS event_id;
END $$

-- ****************************************************************************
-- Delete an event
-- ===============
--
-- Pass in an event ID and delete the corresponding event. Only allow if there
-- are no associated participants or other activity recorded against the event.
-- ****************************************************************************
-- TODO

-- ****************************************************************************
-- Edit an event
-- =============
--
-- Pass in an event ID and update the description to the value provided.
-- Returns a result set containing a success flag and status message.
-- ****************************************************************************
CREATE PROCEDURE sp_edit_event(
    IN p_event_id   INT(10),
    IN p_name       VARCHAR(150)
)
BEGIN
    DECLARE exit HANDLER FOR 1062
    BEGIN
        SELECT 0 AS ok, CONCAT(
            'Event with name "', p_name,
            '" already exists.'
        ) AS outcome;
    END;

    UPDATE event
       SET name = p_name
     WHERE id = p_event_id ;

    IF ROW_COUNT() = 0 THEN
        SELECT 0 AS ok, CONCAT(
            'Event ', p_event_id,
            ' does not exist.'
        ) AS outcome;
    ELSE
        SELECT 1 AS ok, CONCAT(
            'Event ', p_event_id,
            ' updated successfully.'
        ) AS outcome;
    END IF;
END $$

-- ****************************************************************************
-- List Participants for a given Event
-- ===================================
--
-- Returns a result set of all the participants in the database for the
-- given event.
-- ****************************************************************************
CREATE PROCEDURE sp_list_event_participants(
    IN p_event_id   INT
)
BEGIN
    SELECT ep.event_id, 
           ep.participant_id,
           p.name
    FROM event_participant    ep,
         participant          p
    WHERE ep.participant_id = p.id
    AND ep.event_id = p_event_id ;
END $$

-- ****************************************************************************
-- Add a participant to a given Event - By ID
-- ==========================================
--
-- Add an existing participant to an event using their participant ID. Checks  
-- for duplicates and foreign key violations (e.g. adding a participant that
-- doesn't exist).
-- ****************************************************************************
CREATE PROCEDURE sp_add_event_participant_by_id(
    IN p_event_id INT,
    IN p_participant_id INT
)
BEGIN
    DECLARE exit HANDLER FOR 1062
    BEGIN
        SELECT 0 AS ok ,CONCAT(
            'Participant ', p_participant_id,
            ' is already attending event ', p_event_id, '.'
        ) AS outcome;
    END;

    DECLARE exit HANDLER FOR 1452
    BEGIN
        SELECT 0 as ok, CONCAT(
            'Participant ', p_participant_id,
            ' does not exist, cannot add to event ', p_event_id, '.'
        ) AS outcome;
    END;

    -- Normal insert attempt
    INSERT INTO event_participant (event_id, participant_id)
    VALUES (p_event_id, p_participant_id);

    -- If we reach here, the insert succeeded
    SELECT 1 AS ok, CONCAT(
        'Participant ', p_participant_id,
        ' added to event ', p_event_id, '.'
    ) AS outcome;
END;
$$

-- ****************************************************************************
-- Remove a participant from a given Event - By ID
-- ===============================================
--
-- Remove a participant from a given event, use the event id and the
-- participant id..
-- ****************************************************************************
CREATE PROCEDURE sp_remove_event_participant_by_id(
    IN p_event_id INT,
    IN p_participant_id INT
)
BEGIN

    DELETE FROM event_participant
     WHERE event_id       = p_event_id
       AND participant_id = p_participant_id ;

    -- Return a status message indicating the outcome
    IF ROW_COUNT() = 0 THEN
        SELECT 0 AS ok, CONCAT(
            'No participant ', p_participant_id,
            ' attending event ', p_event_id, '.'
        ) AS outcome;
    ELSE
        SELECT 1 AS ok, CONCAT(
            'Participant ', p_participant_id,
            ' removed from event ', p_event_id, '.'
        ) AS outcome;
    END IF;
END $$



/*

-- ****************************************************************************
-- Add Participants for a given Event - By Name
-- ============================================
--
-- Add new participant to an event using their name. This will create a new
-- participant item which will be added to the event using it's ID. Will need 
-- to check that an existing participant with the same name doesn't already
-- exist.
-- ****************************************************************************
CREATE PROCEDURE sp_add_participant_by_name(
    IN p_event_id INT,
    IN p_participant_name VARCHAR(100)
)
BEGIN
    -- Does the name already exist?
    DECLARE name_exists INT DEFAULT 0;

    -- Check if the participant is already linked to the event
    SELECT COUNT(*)
    INTO name_exists
    FROM participants
    WHERE name = p_event_id
      AND participant_id = p_participant_name;

    -- If the name already exists
    IF name_exists = 0 THEN
        INSERT INTO event_participants (event_id, participant_id)
        VALUES (p_event_id, p_participant_id);
    END IF;    
    INSERT INTO event_participants (event_id, participant_id)
    VALUES (p_event_id, p_participant_id) ;

    SELECT *
    FROM event_participants
    WHERE event_id = p_event_id
    AND participant_id = p_participant_id ;
END $$


CREATE PROCEDURE add_plate(
    IN p_event_id INT,
    IN p_person_id INT
)
BEGIN
    INSERT INTO plates (event_id, person_id, created_at)
    VALUES (p_event_id, p_person_id, NOW());
END$$

CREATE PROCEDURE get_total_for_person(
    IN p_event_id INT,
    IN p_person_id INT
)
BEGIN
    SELECT COUNT(*) AS total
    FROM plates
    WHERE event_id = p_event_id
      AND person_id = p_person_id;
END$$

CREATE PROCEDURE get_totals_for_event(
    IN p_event_id INT
)
BEGIN
    SELECT 
        p.person_id,
        p.person_name,
        COUNT(pl.plate_id) AS total
    FROM people p
    LEFT JOIN plates pl
        ON pl.person_id = p.person_id
       AND pl.event_id = p_event_id
    GROUP BY p.person_id, p.person_name
    ORDER BY total DESC, p.person_name ASC;
END$$



CREATE PROCEDURE delete_last_plate(
    IN p_event_id INT,
    IN p_person_id INT
)
BEGIN
    DELETE FROM plates
    WHERE plate_id = (
        SELECT plate_id
        FROM plates
        WHERE event_id = p_event_id
          AND person_id = p_person_id
        ORDER BY created_at DESC
        LIMIT 1
    );
END$$

*/

-- ****************************************************************************
-- Update a plate count for a given participant at a given event
-- =============================================================
--
-- Pass in the event id, event participant id and event plate id with the 
-- quantity to adjust by (expected to be +1 or -1). Check for an existing row,
-- if one is found then update the quantity by the specified amount.
--
-- If no existing row is found, return an ok code of 0 and an appropriate
-- status message.
--
-- If the adjustment value is not +1 or -1, return an ok code of 0 and an
-- appropriate status message.
-- ****************************************************************************
CREATE PROCEDURE sp_update_event_participant_plate_count(
    IN p_event_id INT,
    IN p_event_participant_id INT,
    IN p_event_plate_id INT,
    IN p_adjustment INT
)
BEGIN
    DECLARE existing_qty INT DEFAULT 0;
    
    -- Validate that adjustment is either +1 or -1
    IF p_adjustment NOT IN (1, -1) THEN
        SELECT 0 AS ok, CONCAT(
            'Invalid adjustment value: ',
            p_adjustment,
            '. Must be +1 or -1.'
        ) AS outcome;
    ELSE
        -- Try to update the existing record
        UPDATE event_plate_consumption
           SET quantity = quantity + p_adjustment
         WHERE event_id = p_event_id
           AND participant_id = p_event_participant_id
           AND plate_id = p_event_plate_id;
        
        -- Check if any row was updated
        IF ROW_COUNT() > 0 THEN
            -- Re-select the updated quantity to check if it went negative
            SELECT quantity INTO existing_qty
            FROM event_plate_consumption
            WHERE event_id = p_event_id
              AND participant_id = p_event_participant_id
              AND plate_id = p_event_plate_id;
            
            -- Check the result - if quantity went negative, rollback and report error
            IF existing_qty < 0 THEN
                UPDATE event_plate_consumption
                   SET quantity = 0
                 WHERE event_id = p_event_id
                   AND participant_id = p_event_participant_id
                   AND plate_id = p_event_plate_id;
                
                SELECT 0 AS ok, CONCAT(
                    'Cannot decrease plate count below zero.'
                ) AS outcome;
            ELSE
                SELECT 1 AS ok, CONCAT(
                    'Plate count updated successfully.'
                ) AS outcome;
            END IF;
        ELSE
            -- No existing record, this is an error condition. When the event 
            -- was created, a plate count for each plate was initialised to 
            -- zero for each participant, so if we don't find a record here
            -- it means something has gone wrong.
            
            SELECT 0 AS ok, CONCAT(
                'Unexpected error: No row found for participant ',
                p_event_participant_id,
                ' at event ',
                p_event_id,
                ' with plate ', 
                p_event_plate_id,
                '.'
            ) AS outcome;
            
        END IF;
    END IF;
END $$

DELIMITER ;
