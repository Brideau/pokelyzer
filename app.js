var bunyan = require('bunyan');
var express = require('express');
var bodyParser = require('body-parser');
var moment = require('moment')

var gaussian = require('gaussian');
var dist = gaussian(0, 0.3);

// Set up Postgres connection
var pg = require('pg');
var config = {
  user: process.env.DB_USER || 'pokemon_go_role',
  database: process.env.DB_NAME || 'pokemon_go',
  password: process.env.DB_PASS,
  port: process.env.DB_PORT || DB_PORT,
  max: 20,
  idleTimeoutMillis: 30000
}
var pool = new pg.Pool(config);

var log = bunyan.createLogger({
  name: 'MainApp',
  streams: [
    {
      level: 'info',
      stream: process.stdout
    }
  ]
});

var app = express();
app.use(bodyParser.urlencoded({extended : true}));
app.use(bodyParser.json());

var server = require('http').Server(app);
var port = process.env.WS_PORT || 9876;

var era = process.env.ERA || 2;

server.listen(port, function (err) {
  log.info('Running server on port ' + port);
});

app.post('/', function(req, res) {
    var body = req.body;
    if (body.type == "pokemon") {

      var m = body.message;
      m.pokemon_go_era = era;
      m.hidden_time_unix_s = m.disappear_time;
      m.hidden_time_utc = moment
        .unix(m.hidden_time_unix_s)
        .format("YYYY-MM-DD HH:mm:ss");
      m.latitude_jittered = m.latitude + dist.ppf(Math.random()) * 0.0005;
      m.longitude_jittered = m.longitude + dist.ppf(Math.random()) * 0.0005;

      log.debug(m);

      pool.connect(function(err, client, done) {
        if(err) {
          return log.error('Error fetching client from pool', err);
        }

        query_string = `INSERT INTO spotted_pokemon (
          encounter_id,
          last_modified_time,
          time_until_hidden_ms,
          hidden_time_unix_s,
          hidden_time_utc,
          spawnpoint_id,
          longitude,
          latitude,
          pokemon_id,
          longitude_jittered,
          latitude_jittered,
          pokemon_go_era)
        VALUES (
          '` + m.encounter_id + `'::varchar,
          ` + m.last_modified_time + `::bigint,
          ` + m.time_until_hidden_ms + `::bigint,
          ` + m.hidden_time_unix_s + `::bigint,
          '` + m.hidden_time_utc + `'::timestamp,
          '` + m.spawnpoint_id + `'::varchar,
          ` + m.longitude + `::double precision,
          ` + m.latitude + `::double precision,
          ` + m.pokemon_id + `::smallint,
          ` + m.longitude_jittered + `::double precision,
          ` + m.latitude_jittered + `::double precision,
          ` + m.pokemon_go_era + `::integer
        )
        ON CONFLICT (encounter_id)
        DO UPDATE
          SET last_modified_time = EXCLUDED.last_modified_time,
          time_until_hidden_ms = EXCLUDED.time_until_hidden_ms,
          hidden_time_unix_s = EXCLUDED.hidden_time_unix_s,
          hidden_time_utc = EXCLUDED.hidden_time_utc;`;

        log.info()
        log.debug(query_string);

        client.query(query_string,
        function(err, result) {
          done();

          if(err) {
            return log.error("Error running query", err);
          }
        });
      });

      pool.on('error', function(err, client) {
        log.error('Idle client error', err.message, err.stack);
      });

    }
});
