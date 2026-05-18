-- Test script for sushi_scoreboard database
-- This script creates an event, assigns some users and creates plate and menu lists for the event.
--
use sushi_scoreboard ;

-- Delete all events and associated data
delete from event_menu_consumption ;
delete from event_plate_consumption ;
delete from event ;

-- List current events - should be none
call sp_list_events() ;

-- Create a new event
call sp_create_event('Sushi Night', '2024-07-01', @new_event_id) ;

SELECT CONCAT('New event ID: ', @new_event_id) AS message ;

-- List events again - should show the new event
call sp_list_events() ;

-- Add some participants to the event
call sp_add_event_participant_by_id(@new_event_id, 1) ; -- Tom
call sp_add_event_participant_by_id(@new_event_id, 2) ; -- Dick

-- List participants for the event
call sp_list_event_participants(@new_event_id) ;

-- Set up plates and menu items associated with the event
call sp_event_setup_menu_items(@new_event_id) ;
call sp_event_setup_plates(@new_event_id) ;

\. ./showlastevent.sql