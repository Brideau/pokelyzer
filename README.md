# Pokelyzer

A data model for doing geospatial analysis and regular analytics on Pokemon Go data.

![Tableau Screenshot of Spawn Points](http://i.imgur.com/xRY8bLn.png)

## Explanation

These blog posts help to explain what Pokelyzer is, and what it can be used for.

 - [The Original Concept](http://www.whackdata.com/2016/07/25/tool-for-analyzing-mapping-pokemon-go/)
 - [Finding Hotpots for Locally Rare Pokemon Using Tableau](http://www.whackdata.com/2016/07/27/finding-locally-rare-pokemon/)
 - [Help Others Find Rare Pokemon Nearby](http://www.whackdata.com/2016/07/29/help-others-find-rare-pokemon-nearby/)

The schema itself follows the approach of dimensional modelling to keep it fast and flexible. The entire schema currently looks like this:

<img width="1062" alt="screen shot 2016-08-02 at 12 05 15 am" src="https://cloud.githubusercontent.com/assets/844397/17329922/1f6d9764-589b-11e6-9b89-13cf365cb53c.png">

It looks like a lot, but it isn't. `spotted_pokemon` is where all your data goes. The `date_dimension` and `time_dimension` tables let you slice and filter by dates and times, and the `pokemon_info` table lets you do the same with Pokemon information. `_meta` keeps track of changes to the schema itself. `date_dimension`, `time_dimension`, `pokemon_info` and `_meta` all connect to the `spotted_pokemon` table.

## Installation

See the [wiki page](https://github.com/Brideau/pokelyzer/wiki) for installation instructions. 

## Upgrading

If you already have the database running, ensure all of the patches below since your installation date have been applied. I wish there were better version control for databases, but this is the best solution I have for now. If you know of a better one, let me know.

To use the webhook listener, I recommend doing a fresh installation of PokemonGo-Map using the instructions prodvided in [the wiki ](https://github.com/Brideau/pokelyzer/wiki). Just rename your current directory to something else and do the install. No data will be lost from Pokelyzer since that's stored separately from the PokemonGo-Map database.

## Patches

### July 31, 2016

This is a patch that makes the Pokelyzer capable of accepting data automatically pushed by PokemonGo-Map via its webhood interface.

First, we'll drop the `Name` column from the `spotted_pokemon` table. This is redundant now because of our `pokemon_info` table. We also update the `_meta` table with the new schema version.

```
INSERT INTO _meta (db_version, last_update) VALUES ('v1.0-alpha', '2016-07-31');
ALTER TABLE spotted_pokemon DROP COLUMN name;
```


### Jul 30, 2016 ~4:45AM EDT

This patch adds information that makes it easier to debug issues with the database. Specifically, I have added version tracking so that all records stored record the version of the schema they were stored with, along with a timestamp of when each record was stored.

To apply this patch, get the SQL from [the 2016-07-30-metaPatch.sql file in the patches folder above](https://github.com/Brideau/pokelyzer/blob/master/patches/2016-07-30-metaPatch.sql) and apply it to your database. There's no need to stop your web server to apply this.

### Jul 30, 2016 ~10:30AM EDT

This patch adds an extra column that gives us the ability to assign different Pokemon records to different "eras" - a very useful thing to have when doing historical analysis, especially since the recent changes that switched around all the nests.

It's a bit of a longer one, so see the guide here: <http://www.whackdata.com/2016/07/29/the-era-of-eras-pokemon-go-pokelyzer/>

Thanks again to [@zenthere](https://twitter.com/zenthere) for supplying the SQL for this as well!

### Jul 28, 2016 ~7:39PM EDT

A big thanks to [@zenthere](https://twitter.com/zenthere) for fixing a bug in my jitter calculation, and for creating a beautiful solution to the fact that a lot of rows in the database were duplicates. **(Also note, if you don't apply this patch you'll receive a "there is no unique or exclusion constraint" error.)** To apply this patch, shut down your map server and execute the following SQL to remove all current duplicates and put a constraint on any new ones:

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

And then use the same Restore feature you used to load the database initially to load the [pokemon_into_table_patch.tar file](https://github.com/Brideau/pokelyzer/raw/master/patches/pokemon_info_table_patch.tar) available in patches folder above.

### Jul 27, 2016 ~11PM EDT

If you loaded the database backup file before this time ([commit bd81308](https://github.com/Brideau/pokelyzer/commit/bd813085e0ce5518ae55e33dcc87241b710fb215)), run the following command to patch your existing database. It fixes an issue with joining tables in Tableau.

```sql
ALTER TABLE date_dimension ALTER COLUMN date_key TYPE integer USING (date_key::integer);
```
