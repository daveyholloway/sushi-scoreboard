-- List current events - should be none
call sp_list_events() ;

-- Create a new event
call sp_create_event('Sushi Night', '2024-07-01') ;

-- List events again - should show the new event
call sp_list_events() ;

-- Add some participants to the event
call sp_add_event_participant_by_id(1, 1) ; -- Tom
call sp_add_event_participant_by_id(1, 2) ; -- Dick

-- List participants for the event
call sp_list_event_participants(1) ;
