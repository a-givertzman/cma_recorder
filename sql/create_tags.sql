/*
    PROCESS TAG
*/
do $$
begin
    if not exists (SELECT 1 FROM pg_type WHERE typname = 'tag_type_enum') THEN
        create type public.tag_type_enum as enum('Bool','Int','UInt','DInt','Word','LInt','Real','Time','Date_And_Time');
    end if;
end
$$;
create table if not exists public.tags (
    id 		serial not null,
    type      tag_type_enum not null,
    name      varchar(255) not null unique,
    description   varchar(255) not null DEFAULT '',
    PRIMARY KEY (id)
);
comment on table public.tags is 'Tag dictionary';