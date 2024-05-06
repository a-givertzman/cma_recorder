/*
    PROCESS EVENT
*/
drop trigger if exists event_delete_trigger on event;
drop function if exists event_counter_dec();
drop trigger if exists event_insert_trigger on event;
drop function if exists event_counter_inc();
drop function if exists event_check_for_purge();
drop function if exists event_purge_records();
drop table if exists event_utils;
drop table if exists event;
