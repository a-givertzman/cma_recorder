read -r -d '' sql << EOF
do \$\$
begin
    if not exists (SELECT 1 FROM pg_user WHERE usename = '$user') THEN
        CREATE USER $user WITH PASSWORD '$pass' CREATEDB CREATEROLE;
    end if;
end
\$\$;
EOF
