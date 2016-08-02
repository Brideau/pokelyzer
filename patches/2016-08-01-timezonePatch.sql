INSERT INTO _meta (db_version, last_update) VALUES ('v1.1-alpha', '2016-07-31');

SELECT pg_terminate_backend(pg_stat_activity.pid)
FROM pg_stat_activity
WHERE pg_stat_activity.datname = 'pokemon_go'
  AND pid <> pg_backend_pid();

CREATE DATABASE pokemon_go_backup WITH TEMPLATE pokemon_go OWNER pokemon_go_role;


ALTER TABLE public.spotted_pokemon ADD COLUMN hidden_time_local integer;
ALTER TABLE public.spotted_pokemon ADD COLUMN hidden_time_local integer;


BEGIN;
SET LOCAL timezone='UTC'; -- Only for this block, not permanently
ALTER TABLE spotted_pokemon ALTER COLUMN hidden_time_utc TYPE TIMESTAMP WITH TIME ZONE USING hidden_time_utc AT TIME ZONE 'UTC';
COMMIT;

--- Need to add new views of the original date/time tables
