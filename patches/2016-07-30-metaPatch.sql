-- Create a new table for storing metadata about the schema
CREATE TABLE public._meta (
  id serial,
  db_version text,
  last_update date
);
INSERT INTO _meta (db_version, last_update) VALUES ('v0.5', '2016-07-30');

-- Add a new column that stores the version of the database used when the row was recorded

ALTER TABLE spotted_pokemon ADD COLUMN meta_db_version text DEFAULT 'not versioned';

CREATE OR REPLACE FUNCTION get_db_version()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $BODY$
DECLARE
  payload text;
BEGIN
    NEW.meta_db_version = (SELECT db_version FROM _meta ORDER BY id DESC LIMIT 1);
    RETURN NEW;
END
$BODY$;

CREATE TRIGGER get_db_version_trigger
BEFORE INSERT OR UPDATE
ON spotted_pokemon
FOR EACH ROW
EXECUTE PROCEDURE get_db_version();

-- Log the time each record was recorded

ALTER TABLE spotted_pokemon ADD COLUMN meta_row_insertion_time timestamp;

CREATE OR REPLACE FUNCTION get_row_insertion_time()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $BODY$
DECLARE
  payload text;
BEGIN
    NEW.meta_row_insertion_time = timezone('UTC', CURRENT_TIMESTAMP);
    RETURN NEW;
END
$BODY$;

CREATE TRIGGER row_insertion_time_trigger
BEFORE INSERT OR UPDATE
ON spotted_pokemon
FOR EACH ROW
EXECUTE PROCEDURE get_row_insertion_time();
