# Pokelyzer

A data model for doing geospatial analysis and regular analytics on Pokemon Go data. Instructions available [here](http://www.whackdata.com/2016/07/26/instructions-analyzing-pokemon-go-data/) (will be putting them in the wiki soon).

![Tableau Screenshot of Spawn Points](http://i.imgur.com/xRY8bLn.png)

## Patches

**Jul 27, 2016 ~11PM EDT **

If you loaded the database backup file before this time ([commit bd81308](https://github.com/Brideau/pokelyzer/commit/bd813085e0ce5518ae55e33dcc87241b710fb215)), run the following command to patch your existing database. It fixes an issue with joining tables in Tableau.

```sql
ALTER TABLE date_dimension ALTER COLUMN date_key TYPE integer USING (date_key::integer);
```
