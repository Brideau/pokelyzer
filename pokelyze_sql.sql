-- Create the main tables

CREATE TABLE public.spotted_pokemon(
	id serial NOT NULL,
	name varchar(40) NOT NULL,
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
	longitude_jittered float,
	latitude_jittered float,
	geo_point geometry,
	geo_point_jittered geometry,
	CONSTRAINT id_primary_key PRIMARY KEY (id)

);

CREATE TABLE public.pokemon_info(
	pokemon_id smallint NOT NULL,
	name varchar(40),
	type varchar(40),
	rarity varchar(30),
	CONSTRAINT pokemon_id_primary PRIMARY KEY (pokemon_id)

);

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

CREATE INDEX name_index
  ON public.spotted_pokemon
  USING btree (name);

CREATE INDEX point_index
  ON public.spotted_pokemon
  USING gist
  (geo_point);

CREATE INDEX pokemon_id_index
  ON public.spotted_pokemon
  USING btree
  (pokemon_id);

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

