DELETE FROM spotted_pokemon USING spotted_pokemon sp2
  WHERE spotted_pokemon.encounter_id = sp2.encounter_id AND spotted_pokemon.id > sp2.id;
ALTER TABLE spotted_pokemon ADD CONSTRAINT encounter_id_unique UNIQUE (encounter_id);