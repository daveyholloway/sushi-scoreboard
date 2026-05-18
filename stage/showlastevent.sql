-- Find the latest event and show the participants and 
-- available menu items and plates.
-- Used for debugging.

use sushi_scoreboard ;

-- Get the latest event id
select max(id) into @new_event_id from event ;

-- Show attendees and menu / plates for the event
SELECT e.id, e.name, event_date
  FROM event e
 WHERE e.id = @new_event_id ;

SELECT CONCAT(p.name, " (", ep.id, ") is attending event ", ep.event_id) AS message
  FROM event_participant ep
  JOIN participant p ON ep.participant_id = p.id
 WHERE ep.event_id = @new_event_id ;

 SELECT ep.event_id, ep.id, pl.name, pl.hex_colour,ep.price 
   FROM event_plate ep
   JOIN plate pl ON ep.plate_id = pl.id
  WHERE ep.event_id = @new_event_id ;

 SELECT em.event_id, em.id, mi.name, mi.price 
   FROM event_menu_item em
   JOIN menu_item mi ON em.menu_item_id = mi.id
  WHERE em.event_id = @new_event_id ;

