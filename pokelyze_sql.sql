----------- The main fact table, spotted pokemon-------------

CREATE TABLE public.spotted_pokemon(
	id bigserial NOT NULL,
	encounter_id varchar(40),
	last_modified_time bigint,
	time_until_hidden_ms bigint,
	hidden_time_unix_s bigint,
	hidden_time_utc timestamp without time zone,
	spawnpoint_id varchar(20),
	longitude double precision,
	latitude double precision,
	pokemon_id smallint,
	time_key smallint,
	date_key integer,
	longitude_jittered double precision,
	latitude_jittered double precision,
	geo_point geometry,
	geo_point_jittered geometry,
	pokemon_go_era integer,
	meta_db_version text DEFAULT 'not versioned'::text,
	meta_row_insertion_time timestamp without time zone,
	CONSTRAINT encounter_id_unique UNIQUE (encounter_id),
	CONSTRAINT id_primary_key PRIMARY KEY (id)

);
ALTER TABLE public.spotted_pokemon
  OWNER TO pokemon_go_role;

CREATE INDEX jitter_index
  ON public.spotted_pokemon
  USING gist
  (geo_point_jittered);

CREATE INDEX latitude_index
  ON public.spotted_pokemon
  USING btree
  (latitude);

CREATE INDEX latitude_jit_index
  ON public.spotted_pokemon
  USING btree
  (latitude_jittered);

CREATE INDEX longitude_index
  ON public.spotted_pokemon
  USING btree
  (longitude);

CREATE INDEX longitude_jit_index
  ON public.spotted_pokemon
  USING btree
  (longitude_jittered);

CREATE INDEX point_index
  ON public.spotted_pokemon
  USING gist
  (geo_point);

CREATE INDEX pokemon_id_index
  ON public.spotted_pokemon
  USING btree
  (pokemon_id);

-------- The pokemon info dimension table ------------

CREATE TABLE public.pokemon_info
(
  pokemon_id bigint NOT NULL,
  name text,
  classification text,
  type_1 text,
  type_2 text,
  weight double precision,
  height double precision,
  CONSTRAINT pokemon_info_pkey PRIMARY KEY (pokemon_id)
)
ALTER TABLE public.pokemon_info
	OWNER TO pokemon_go_role;
CREATE INDEX pokemon_info_pokemon_id_idx
  ON public.pokemon_info
  USING btree
  (pokemon_id);

CREATE INDEX pokemon_info_pokemon_name_index
  ON public.pokemon_info
  USING btree
  (name);

-------- The meta table for recording schema versions

CREATE TABLE public._meta (
  id serial,
  db_version text,
  last_update date
);
ALTER TABLE public.public
	OWNER TO pokemon_go_role;
INSERT INTO _meta (db_version, last_update) VALUES ('v1.0.1-alpha', '2016-08-01');


--- The time and date dimensions are created with a python script


-- Create a point from the latitude and longitude of pokemon

CREATE OR REPLACE FUNCTION create_point_from_lon_lat()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $BODY$
DECLARE
  payload text;
BEGIN
    NEW.geo_point = St_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326);
    RETURN NEW;
END
$BODY$;

CREATE TRIGGER compute_point
BEFORE INSERT OR UPDATE
ON spotted_pokemon
FOR EACH ROW
EXECUTE PROCEDURE create_point_from_lon_lat();

-- Create a point from the JITTERED latitude and longitude of pokemon

CREATE OR REPLACE FUNCTION create_point_from_lon_lat_jit()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $BODY$
DECLARE
  payload text;
BEGIN
    NEW.geo_point_jittered = St_SetSRID(ST_MakePoint(NEW.longitude_jittered, NEW.latitude_jittered), 4326);
    RETURN NEW;
END
$BODY$;

CREATE TRIGGER compute_point_jittered
BEFORE INSERT OR UPDATE
ON spotted_pokemon
FOR EACH ROW
EXECUTE PROCEDURE create_point_from_lon_lat_jit();

-- Create a date key from the timestamp to be used with the date dimension table

CREATE OR REPLACE FUNCTION create_datekey_fn()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $BODY$
DECLARE
  payload text;
BEGIN
    NEW.date_key = NULLIF(to_char(NEW.hidden_time_utc, 'YYYYMMDD'), '')::int;
    RETURN NEW;
END
$BODY$;

DROP TRIGGER IF EXISTS create_datekey ON spotted_pokemon;
CREATE TRIGGER create_datekey
BEFORE INSERT OR UPDATE
ON spotted_pokemon
FOR EACH ROW
EXECUTE PROCEDURE create_datekey_fn();

-- Create a time key from the timestamp to be used with the time dimension table

CREATE OR REPLACE FUNCTION create_timekey_fn()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $BODY$
DECLARE
  payload text;
BEGIN
    NEW.time_key = to_char(NEW.hidden_time_utc, 'MI')::int + (to_char(NEW.hidden_time_utc, 'HH24')::int * 60);
    RETURN NEW;
END
$BODY$;

DROP TRIGGER IF EXISTS create_timekey ON spotted_pokemon;
CREATE TRIGGER create_timekey
BEFORE INSERT OR UPDATE
ON spotted_pokemon
FOR EACH ROW
EXECUTE PROCEDURE create_timekey_fn();

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
