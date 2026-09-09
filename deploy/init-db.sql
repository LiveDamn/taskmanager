SELECT 'CREATE ROLE taskmanager LOGIN PASSWORD ''taskmanager'''
WHERE NOT EXISTS (
    SELECT FROM pg_roles WHERE rolname = 'taskmanager'
)\gexec

SELECT 'CREATE DATABASE taskmanager OWNER taskmanager'
WHERE NOT EXISTS (
    SELECT FROM pg_database WHERE datname = 'taskmanager'
)\gexec