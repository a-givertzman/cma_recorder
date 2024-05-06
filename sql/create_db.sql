SELECT 'CREATE DATABASE crane_data_server'
        WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'crane_data_server')\gexec
