INSERT INTO _meta (db_version, last_update) VALUES ('v1.3-alpha', '2016-08-03');

-- Set the timezone in the postgresql.conf file. To find out the long-form name to use, try the following command using the abbreviation.
-- SELECT * FROM pg_timezone_names WHERE abbrev = 'PDT';


-- Drop and replace the existing functions so that we replace them with simplified versions.

DROP TRIGGER compute_point ON spotted_pokemon;
DROP TRIGGER compute_point_jittered ON spotted_pokemon;
DROP TRIGGER create_datekey ON spotted_pokemon;
DROP TRIGGER create_timekey ON spotted_pokemon;
DROP TRIGGER get_db_version_trigger ON spotted_pokemon;
DROP TRIGGER row_insertion_time_trigger ON spotted_pokemon;

DROP FUNCTION create_datekey_fn();
DROP FUNCTION create_point_from_lon_lat();
DROP FUNCTION create_point_from_lon_lat_jit();
DROP FUNCTION create_timekey_fn();
DROP FUNCTION get_db_version();
DROP FUNCTION get_row_insertion_time();

-- Cleans up some of the column types since it doesn't benefit us to us varchars in postgres
ALTER TABLE public.spotted_pokemon ALTER COLUMN encounter_id TYPE text;
ALTER TABLE public.spotted_pokemon ALTER COLUMN spawnpoint_id TYPE text;
ALTER TABLE public.spotted_pokemon ALTER COLUMN pokemon_go_era TYPE smallint;


-- Create a new timestamp column from the UTC column based on the timezone of the database
ALTER TABLE public.spotted_pokemon ADD COLUMN hidden_time_local TIMESTAMP WITH TIME ZONE;
ALTER TABLE public.spotted_pokemon ADD COLUMN time_key_local smallint;
ALTER TABLE public.spotted_pokemon ADD COLUMN date_key_local integer;

CREATE INDEX spotted_pokemon_date_key
  ON public.spotted_pokemon
  USING btree
  (date_key);

CREATE INDEX spotted_pokemon_time_key
  ON public.spotted_pokemon
  USING btree
  (time_key);

CREATE INDEX spotted_pokemon_date_key_local
  ON public.spotted_pokemon
  USING btree
  (date_key_local);

CREATE INDEX spotted_pokemon_time_key_local
  ON public.spotted_pokemon
  USING btree
  (time_key_local);

-- Add geospatial data to each row

CREATE OR REPLACE FUNCTION create_geospatial_data_fn()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $BODY$
BEGIN
    NEW.geo_point = St_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326);
    NEW.geo_point_jittered = St_SetSRID(ST_MakePoint(NEW.longitude_jittered, NEW.latitude_jittered), 4326);
    RETURN NEW;
END
$BODY$;

CREATE TRIGGER create_geospatial_data
BEFORE INSERT OR UPDATE
ON spotted_pokemon
FOR EACH ROW
EXECUTE PROCEDURE create_geospatial_data_fn();

-- Add data and time keys to each row

CREATE OR REPLACE FUNCTION add_date_time_keys_fn()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $BODY$
BEGIN
    NEW.date_key = NULLIF(to_char(NEW.hidden_time_utc, 'YYYYMMDD'), '')::int;
    NEW.time_key = to_char(NEW.hidden_time_utc, 'MI')::int + (to_char(NEW.hidden_time_utc, 'HH24')::int * 60);
    NEW.hidden_time_local = NEW.hidden_time_utc AT TIME ZONE 'UTC';
    NEW.time_key_local = to_char(NEW.hidden_time_local, 'MI')::int + (to_char(NEW.hidden_time_local, 'HH24')::int * 60);
    NEW.date_key_local = NULLIF(to_char(NEW.hidden_time_local, 'YYYYMMDD'), '')::int;
    RETURN NEW;
END
$BODY$;

CREATE TRIGGER add_date_time_keys
BEFORE INSERT OR UPDATE
ON spotted_pokemon
FOR EACH ROW
EXECUTE PROCEDURE add_date_time_keys_fn();

--- Add metadata to each row

CREATE OR REPLACE FUNCTION get_meta_data_fn()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $BODY$
BEGIN
    NEW.meta_db_version = (SELECT db_version FROM _meta ORDER BY id DESC LIMIT 1);
    NEW.meta_row_insertion_time = timezone('UTC', CURRENT_TIMESTAMP);
    RETURN NEW;
END
$BODY$;

CREATE TRIGGER get_meta_data
BEFORE INSERT
ON spotted_pokemon
FOR EACH ROW
EXECUTE PROCEDURE get_meta_data_fn();

UPDATE public.spotted_pokemon SET hidden_time_utc = CAST(to_timestamp(hidden_time_unix_s) AT TIME ZONE 'UTC' AS timestamp);


-- Add new views of the original date and time tables in case people want to use both. Also help with user-friendliness in Tableau.

CREATE VIEW date_dimension_local AS SELECT
	date_key AS date_key_local,
	full_date,
	day_of_week,
	day_of_week_name,
	day_of_week_name_abbrev,
	day_of_month,
	day_number_overall,
	weekday_flag,
	week_number,
	week_number_overall,
	week_begin_date,
	week_begin_date_key,
	month_number,
	month_number_overall,
	month,
	month_abbrev,
	quarter,
	year,
	year_month,
	month_end_flag
FROM date_dimension;

CREATE VIEW time_dimension_local AS SELECT
	time_key AS time_key_local,
	time_label_24,
	time_label_12,
	time_interval_15min,
	time_interval_30min,
	time_interval_60min,
	label_hh,
	label_hh24,
	label_15min_24,
	label_30min_24,
	label_60min_24,
	label_15min_12,
	label_30min_12,
	label_60min_12
FROM time_dimension;

SELECT *
FROM spotted_pokemon
ORDER BY id DESC LIMIT 5;

-- Fix the bug where I forgot to decode the encounter_id

-- First turn off the unique constraint that we have so we don't get conflicts during this update
ALTER TABLE spotted_pokemon DROP CONSTRAINT encounter_spawnpoint_id_unique;

-- Then decode all the rows that aren't numeric
UPDATE public.spotted_pokemon 
SET encounter_id = decode(encounter_id, 'base64')
WHERE NOT encounter_id ~ '^([0-9]+[.]?[0-9]*|[.][0-9]+)$';

-- Then delete any duplicates based on the encounter_id and spawnpoint_id
DELETE FROM public.spotted_pokemon 
WHERE id IN (SELECT id
              FROM (SELECT id, ROW_NUMBER() OVER (partition BY encounter_id, spawnpoint_id ORDER BY id) AS rnum
                     FROM public.spotted_pokemon ) AS t
              WHERE t.rnum > 1);

-- Then add the constraint back
ALTER TABLE public.spotted_pokemon
  ADD CONSTRAINT encounter_spawnpoint_id_unique UNIQUE(encounter_id, spawnpoint_id);









