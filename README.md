# Pokelyzer

A data model for doing geospatial analysis and regular analytics on Pokemon Go data. Instructions available [here](http://www.whackdata.com/2016/07/26/instructions-analyzing-pokemon-go-data/) (will be putting them in the wiki soon).

![Tableau Screenshot of Spawn Points](http://i.imgur.com/xRY8bLn.png)

## Patches

### Jul 30, 2016 ~10:30AM EDT

This patch adds an extra column that gives us the ability to assign different Pokemon records to different "eras" - a very useful thing to have when doing historical analysis.

Simply stop your server, and run this SQL:

```sql
ALTER TABLE public.spotted_pokemon ADD COLUMN pokemon_go_era integer;

UPDATE public.spotted_pokemon
SET pokemon_go_era = '1'
WHERE hidden_time_utc < '2016-07-29 15:00:00';

UPDATE public.spotted_pokemon
SET pokemon_go_era = '2'
WHERE hidden_time_utc >= '2016-07-29 15:00:00';
```

Then update your `utils.py` and `customLog.py` files to match the sample ones above, and start your server back up.

### Jul 28, 2016 ~7:39PM EDT

A big thanks to [@zenthere](https://twitter.com/zenthere) for fixing a bug in my jitter calculation, and for creating a beautiful solution to the fact that a lot of rows in the database were duplicates. To apply this patch, shut down your map server and execute the following SQL to remove all current duplicates and put a constraint on any new ones:

```sql
DELETE FROM spotted_pokemon USING spotted_pokemon sp2
  WHERE spotted_pokemon.encounter_id = sp2.encounter_id AND spotted_pokemon.id > sp2.id;
ALTER TABLE spotted_pokemon ADD CONSTRAINT encounter_id_unique UNIQUE (encounter_id);
```

Then update your [customLog.py file with the one from the Pokelyzer v0.3-alpha release](https://github.com/Brideau/pokelyzer/blob/v0.3-alpha/sample_customLog.py).

Start your server back up!

### Jul 28, 2016 ~12PM EDT

I've added a table for doing analysis using various Pokemon properties, such as type, classification, weight and height. To patch an existing database to support this, first drop the existing pokemon_info table from pgAdmin or using:

```sql
DROP TABLE public.pokemon_info;
```

And then use the same Restore feature you used to load the database initially to load the pokemon_into_table_patch.tar file available in the repo.

### Jul 27, 2016 ~11PM EDT

If you loaded the database backup file before this time ([commit bd81308](https://github.com/Brideau/pokelyzer/commit/bd813085e0ce5518ae55e33dcc87241b710fb215)), run the following command to patch your existing database. It fixes an issue with joining tables in Tableau.

```sql
ALTER TABLE date_dimension ALTER COLUMN date_key TYPE integer USING (date_key::integer);
```
