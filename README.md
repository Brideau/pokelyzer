# Pokelyzer

A data model for doing geospatial analysis and regular analytics on Pokemon Go data. Instructions available [here](http://www.whackdata.com/2016/07/26/instructions-analyzing-pokemon-go-data/) (will be putting them in the wiki soon).

![Tableau Screenshot of Spawn Points](http://i.imgur.com/xRY8bLn.png)

## Webhook Listener Installation Instructions

Before doing this, follow the instructions in the wiki page for setting up the database.

**If you already have the database running, ensure all of the patches mentioned below since your installation date have been applied.** I wish there were better version control for databases, but this is the best solution I have for now. If you know of a better one, let me know.

Once that's complete, return here to complete the remaining instructions.

 - [Install Node.js v4.X](https://nodejs.org/en/) using the installer on the home page or through [the command line](https://nodejs.org/en/download/package-manager/)
 - Make sure npm is up-to-date by running `sudo npm install npm -g`
 - Pull the repo and install the dependencies:
```bash
git clone https://github.com/Brideau/pokelyzer
cd ./pokelyzer
npm install
sudo npm install -g bunyan
```
- Run using:

 ```sql
 DB_NAME='pokemon_go' DB_USER='pokemon_go_role' DB_PASS='[YOUR PASS]' DB_PORT=5432 WS_PORT=9876 ERA=2  node app.js | bunyan -l info
 ```
- Open another terminal window, and clone the develop branch of PokemonGo-Map using the command:

```bash
git clone -b develop https://github.com/AHAAAAAAA/PokemonGo-Map.git
```

 - Follow the instructions available in [their wiki](https://github.com/AHAAAAAAA/PokemonGo-Map/wiki) to complete the install, making sure it is in a separate directory from Pokelyzer
 - When you start the server, ensure that the `-wh` parameter is included, as this tells PokemonGo-Map where to send the data as it comes in. In our case, it's the Pokelyzer Webhook App:

```
 python runserver.py -a ptc -u [Your Username] -p [Your Password] -l "[Your Location]" -st 25 -H 0.0.0.0 -k [Your Google API key] -wh http://localhost:9876
```

This should now start feeding data directly from PokemonGo-Map into your Pokelyzer Webhook listener, and then into your database.

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
