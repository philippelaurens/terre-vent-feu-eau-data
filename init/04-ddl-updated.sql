
SET search_path TO incendies, public;

--
-- Name: commune_jour; Type: TABLE; Schema: incendies; Owner: -
--
CREATE TABLE incendies.commune_jour (
    id_commune integer NOT NULL,
    date_jour date NOT NULL,
    has_fire smallint,
    nb_incendies_30j integer,
    nb_incendies_90j integer,
    nb_incendies_365j integer,
    surface_totale_5a integer,
    buffer_10km integer,
    buffer_20km integer,
    buffer_50km integer,
    surface_50km double precision,
    CONSTRAINT pk_commune_jour PRIMARY KEY (id_commune, date_jour)
);

--
-- Name: v_commune_paca; Type: VIEW; Schema: incendies; Owner: -
--
CREATE VIEW incendies.v_commune_paca AS
 SELECT id_commune,
    code_insee,
    localisation,
    nom_standard,
    region,
    departement,
    population,
    superficie_hectare,
    densite,
    altitude_moyenne,
    altitude_minimale,
    altitude_maximale
   FROM incendies.commune
  WHERE (region = 17);


--
-- Name: mv_communes_voisines_10km; Type: MATERIALIZED VIEW; Schema: incendies; Owner: -
--
CREATE MATERIALIZED VIEW mv_communes_voisines_10km AS
SELECT 
    c1.id_commune AS ref_commune,
    c2.id_commune AS voisin_commune,
    c2.code_insee,
    ST_Distance(l1.geom_m, l2.geom_m) AS distance
FROM v_commune_paca c1
JOIN localisation l1 ON l1.id_localisation = c1.localisation
JOIN localisation l2 ON ST_DWithin(l1.geom_m, l2.geom_m, 10000.0)
JOIN commune c2 ON c2.localisation = l2.id_localisation
WHERE c2.id_commune <> c1.id_commune
WITH NO DATA;
-- Index UNIQUE obligatoire (permet le REFRESH MATERIALIZED VIEW CONCURRENTLY)
CREATE UNIQUE INDEX idx_mv_voisines_10km_pk ON mv_communes_voisines_10km (ref_commune, voisin_commune);
CREATE INDEX idx_mv_voisines_10km_ref ON mv_communes_voisines_10km (ref_commune);
CREATE INDEX idx_mv_cv_code_insee_10 ON incendies.mv_communes_voisines_10km USING btree (code_insee);
CREATE INDEX idx_mv_cv_ref_distance_10 ON incendies.mv_communes_voisines_10km USING btree (ref_commune, distance);

--
-- Name: mv_communes_voisines_20km; Type: MATERIALIZED VIEW; Schema: incendies; Owner: -
--
CREATE MATERIALIZED VIEW mv_communes_voisines_20km AS
SELECT 
    c1.id_commune AS ref_commune,
    c2.id_commune AS voisin_commune,
    c2.code_insee,
    ST_Distance(l1.geom_m, l2.geom_m) AS distance
FROM v_commune_paca c1
JOIN localisation l1 ON l1.id_localisation = c1.localisation
JOIN localisation l2 ON ST_DWithin(l1.geom_m, l2.geom_m, 20000.0)
JOIN commune c2 ON c2.localisation = l2.id_localisation
WHERE c2.id_commune <> c1.id_commune
WITH NO DATA;
-- Index UNIQUE obligatoire (permet le REFRESH MATERIALIZED VIEW CONCURRENTLY)
CREATE UNIQUE INDEX idx_mv_voisines_20km_pk ON mv_communes_voisines_20km (ref_commune, voisin_commune);
CREATE INDEX idx_mv_voisines_20km_ref ON mv_communes_voisines_20km (ref_commune);
CREATE INDEX idx_mv_cv_code_insee_20 ON incendies.mv_communes_voisines_20km USING btree (code_insee);
CREATE INDEX idx_mv_cv_ref_distance_20 ON incendies.mv_communes_voisines_20km USING btree (ref_commune, distance);

--
-- Name: mv_communes_voisines_50km; Type: MATERIALIZED VIEW; Schema: incendies; Owner: -
--
CREATE MATERIALIZED VIEW mv_communes_voisines_50km AS
SELECT 
    c1.id_commune AS ref_commune,
    c2.id_commune AS voisin_commune,
    c2.code_insee,
    ST_Distance(l1.geom_m, l2.geom_m) AS distance
FROM v_commune_paca c1
JOIN localisation l1 ON l1.id_localisation = c1.localisation
JOIN localisation l2 ON ST_DWithin(l1.geom_m, l2.geom_m, 50000.0)
JOIN commune c2 ON c2.localisation = l2.id_localisation
WHERE c2.id_commune <> c1.id_commune
WITH NO DATA;
-- Index UNIQUE obligatoire (permet le REFRESH MATERIALIZED VIEW CONCURRENTLY)
CREATE UNIQUE INDEX idx_mv_voisines_20km_pk ON mv_communes_voisines_50km (ref_commune, voisin_commune);
CREATE INDEX idx_mv_voisines_20km_ref ON mv_communes_voisines_50km (ref_commune);
CREATE INDEX idx_mv_cv_code_insee_50 ON incendies.mv_communes_voisines_50km USING btree (code_insee);
CREATE INDEX idx_mv_cv_ref_distance_50 ON incendies.mv_communes_voisines_50km USING btree (ref_commune, distance);
