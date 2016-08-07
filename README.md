# Pokelyzer

A webhook listener and database schema for doing geospatial analysis and advanced analytics on Pokemon Go data.

![Tableau Screenshot of Spawn Points](http://i.imgur.com/xRY8bLn.png)

## Explanation

These blog posts help to explain what Pokelyzer is, and what it can be used for.

 - [The Original Concept](http://www.whackdata.com/2016/07/25/tool-for-analyzing-mapping-pokemon-go/)
 - [Finding Hotpots for Locally Rare Pokemon Using Tableau](http://www.whackdata.com/2016/07/27/finding-locally-rare-pokemon/)
 - [Help Others Find Rare Pokemon Nearby](http://www.whackdata.com/2016/07/29/help-others-find-rare-pokemon-nearby/)

## The Database Schema

The schema itself follows the approach of dimensional modelling to keep it fast and flexible. The entire schema currently looks like this:

![Schema image](http://imgur.com/4BueNOT.png)

It looks like a lot, but it isn't. `spotted_pokemon` is where all your data goes. The `date_dimension` and `time_dimension` tables let you slice and filter by dates and times, and the `pokemon_info` table lets you do the same with Pokemon information. `_meta` keeps track of changes to the schema itself. `date_dimension`, `time_dimension`, `pokemon_info` and `_meta` all connect to the `spotted_pokemon` table.

## The Webhook Listener

The webhook listener is a node application that listens for POSTS to port 9876 by default, for JSON messages that look like this:

```javascript
{
  "type": "pokemon",
  "message": {
    "encounter_id": "17290083747243295117",
    "spawnpoint_id": "4ca42277a41",
    "pokemon_id": "41",
    "latitude": "45.9586350970765",
    "longitude": "-66.6595416124465",
    "disappear_time": "1469421912",
    "last_modified_time": "1469421858380",
    "time_until_hidden_ms": "54456"
  }
}
```

Where timestamps are in UNIX time. If you are manually submitting data to this endpoint, pass in an additional parameter `ENC_ENC=f` (`set ENC_ENC=f` on Windows) to ensure that it does not try to decode the `encounter_id`, which it has to for the PokemonGo-Map data source.

## Installation

See the [wiki page](https://github.com/Brideau/pokelyzer/wiki) for installation instructions.

## Upgrading

If you already have the database running, ensure all of the patches below since your installation date have been applied. I wish there were better version control for databases, but this is the best solution I have for now. If you know of a better one, let me know.

To use the webhook listener, I recommend doing a fresh installation of PokemonGo-Map using the instructions prodvided in [the wiki ](https://github.com/Brideau/pokelyzer/wiki). Just rename your current directory to something else and do the install. No data will be lost from Pokelyzer since that's stored separately from the PokemonGo-Map database.

## Patches

Before you try to do recent tutorials or install new versions of the webhook listener, please install all patches **since your installation date**.

All patches can be found in the [Patches wiki page](https://github.com/Brideau/pokelyzer/wiki/).
