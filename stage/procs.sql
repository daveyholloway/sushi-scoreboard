USE sushi;

DELIMITER $$

-- Drop everything first (if it exists)
DROP PROCEDURE IF EXISTS sp_list_events;
DROP PROCEDURE IF EXISTS sp_create_event;
DROP PROCEDURE IF EXISTS sp_delete_event;                    --TODO
DROP PROCEDURE IF EXISTS sp_edit_event;                      --TODO
DROP PROCEDURE IF EXISTS sp_list_participants ;
DROP PROCEDURE IF EXISTS sp_add_participant_by_id ;
DROP PROCEDURE IF EXISTS sp_add_participant_by_name ;        --TODO

-- ****************************************************************************
-- List Events
-- ===========
--
-- Returns a result set of all the events in the database.
-- ****************************************************************************
CREATE PROCEDURE sp_list_events()
BEGIN
    SELECT id, name
    FROM events
    ORDER BY id;
END $$

-- ****************************************************************************
-- Create an Event
-- ===============
--
-- Adds a new even with the given name and date, returns a result set
-- containing the new row data.
-- ****************************************************************************
CREATE PROCEDURE sp_create_event(
    IN p_name VARCHAR(150),
    IN p_event_date DATE
)
BEGIN
    INSERT INTO events (name, event_date)
    VALUES (p_name, p_event_date);

    SELECT *
    FROM events
    WHERE id = LAST_INSERT_ID();
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
-- ****************************************************************************
-- TODO

-- ****************************************************************************
-- List Participants for a given Event
-- ===================================
--
-- Returns a result set of all the participants in the database for the
-- given event.
-- ****************************************************************************
CREATE PROCEDURE sp_list_participants(
    IN p_event_id   INT
)
BEGIN
    SELECT ep.event_id, 
           ep.participant_id,
           p.name
    FROM event_participants    ep,
         participants          p
    WHERE ep.participant_id = p.id
    AND ep.event_id = p_event_id ;
END $$

-- ****************************************************************************
-- Add Participants for a given Event - By ID
-- ==========================================
--
-- Add an existing participant to an event using their participant ID. Will not
-- insert duplicates.
-- ****************************************************************************
CREATE PROCEDURE sp_add_participant_by_id(
    IN p_event_id INT,
    IN p_participant_id INT
)
BEGIN
    DECLARE already_exists INT DEFAULT 0;

    -- Check if the participant is already linked to the event
    SELECT COUNT(*)
    INTO already_exists
    FROM event_participants
    WHERE event_id = p_event_id
      AND participant_id = p_participant_id;

    IF already_exists = 0 THEN
        INSERT INTO event_participants (event_id, participant_id)
        VALUES (p_event_id, p_participant_id);
    END IF;

    -- Return the final state (idempotent)
    SELECT *
    FROM event_participants
    WHERE event_id = p_event_id
      AND participant_id = p_participant_id;
END
 $$

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



DELIMITER ;
