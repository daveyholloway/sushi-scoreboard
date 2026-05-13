-- List menu item consumption
select emc.event_id, ev.name, ev.event_date, emc.event_participant_id, p.name, emc.event_menu_item_id, mi.name, emi.price, emc.quantity
  from event_menu_consumption      emc,
	   event                       ev,
       event_participant           ep,
       participant                 p,
       event_menu_item             emi,
       menu_item                   mi
 where emc.event_id = @new_event_id 
   and ev.id = emc.event_id
   and ep.id = emc.event_participant_id
   and p.id = ep.participant_id
   and emi.event_id = ev.id
   and emc.event_menu_item_id = emi.id
   and emi.menu_item_id = mi.id

-- List plate consumption
select epc.event_id, ev.name, ev.event_date, epc.event_participant_id, p.name, epc.event_plate_id, pl.name, epl.price, epc.quantity
  from event_plate_consumption     epc,
	   event                       ev,
       event_participant           ep,
       participant                 p,
       event_plate                 epl,
       plate                       pl
 where epc.event_id = @new_event_id 
   and ev.id = epc.event_id
   and ep.id = epc.event_participant_id
   and p.id = ep.participant_id
   and epl.event_id = ev.id
   and epc.event_plate_id = epl.id
   and epl.plate_id = pl.id