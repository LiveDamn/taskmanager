SELECT 'CREATE DATABASE "DB" OWNER alexis'
WHERE NOT EXISTS (
    SELECT FROM pg_database WHERE datname = 'DB'
)\gexec