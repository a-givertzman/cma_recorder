do $$
begin
    if exists (SELECT 1 FROM pg_database WHERE datname = 'crane_data_server') THEN
        if exists (SELECT 1 FROM pg_roles WHERE rolname='crane_data_server') then
            GRANT ALL PRIVILEGES ON DATABASE crane_data_server TO crane_data_server;
        end if;
    end if;
end
$$;
