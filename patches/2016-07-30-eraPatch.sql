ALTER TABLE public.spotted_pokemon ADD COLUMN pokemon_go_era integer;

UPDATE public.spotted_pokemon
SET pokemon_go_era = '1'
WHERE hidden_time_utc < '2016-07-29 15:00:00';

UPDATE public.spotted_pokemon
SET pokemon_go_era = '2'
WHERE hidden_time_utc >= '2016-07-29 15:00:00';