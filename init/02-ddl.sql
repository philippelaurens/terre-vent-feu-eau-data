SET search_path TO incendies, public;

--
-- Name: tmp_commune; Type: TABLE; Schema: incendies; Owner: -
--
CREATE TABLE tmp_commune (
    code_insee character varying(10) NOT NULL,
    nom_standard character varying(100) NOT NULL,
    nom_sans_pronom character varying(100) NOT NULL,
    nom_a character varying(100) NOT NULL,
    nom_de character varying(100) NOT NULL,
    nom_sans_accent character varying(100) NOT NULL,
    nom_standard_majuscule character varying(100) NOT NULL,
    typecom character varying(10) NOT NULL,
    typecom_texte character varying(50) NOT NULL,
    reg_code smallint NOT NULL,
    reg_nom character varying(100) NOT NULL,
    dep_code character varying(10) NOT NULL,
    dep_nom character varying(100) NOT NULL,
    canton_code character varying(10),
    canton_nom character varying(100),
    epci_code character varying(20),
    epci_nom character varying(150),
    academie_code smallint NOT NULL,
    academie_nom character varying(100) NOT NULL,
    code_postal character varying(10),
    codes_postaux character varying(200),
    zone_emploi integer,
    code_insee_centre_zone_emploi character varying(10),
    code_unite_urbaine character varying(10),
    nom_unite_urbaine character varying(100),
    taille_unite_urbaine smallint,
    type_commune_unite_urbaine character varying(50),
    statut_commune_unite_urbaine character varying(50),
    population integer NOT NULL,
    superficie_hectare integer NOT NULL,
    superficie_km2 integer NOT NULL,
    densite numeric(10,2),
    altitude_moyenne smallint NOT NULL,
    altitude_minimale smallint NOT NULL,
    altitude_maximale smallint NOT NULL,
    latitude_mairie numeric(9,6) NOT NULL,
    longitude_mairie numeric(9,6) NOT NULL,
    latitude_centre numeric(9,6),
    longitude_centre numeric(9,6),
    grille_densite smallint NOT NULL,
    grille_densite_texte character varying(50) NOT NULL,
    niveau_equipements_services smallint,
    niveau_equipements_services_texte character varying(100),
    gentile character varying(100),
    url_wikipedia character varying(255),
    url_villedereve character varying(255) NOT NULL
);
CREATE INDEX idx_tmp_commune_code_insee ON tmp_commune USING btree (code_insee);
CREATE INDEX idx_tmp_commune_latitude_mairie ON tmp_commune USING btree (latitude_mairie);
CREATE INDEX idx_tmp_commune_longitude_mairie ON tmp_commune USING btree (longitude_mairie);

--
-- Name: tmp_incendie; Type: TABLE; Schema: incendies; Owner: -
--
CREATE TABLE tmp_incendie (
    annee integer NOT NULL,
    numero integer NOT NULL,
    departement character varying(10) NOT NULL,
    insee character varying(10) NOT NULL,
    nom_commune character varying(150),
    date_premiere_alerte character varying(30) NOT NULL,
    surface_parcourue bigint NOT NULL,
    surface_foret numeric(15,2),
    surface_maquis_garrigues numeric(15,2),
    autres_surfaces_naturelles numeric(15,2),
    surfaces_agricoles numeric(15,2),
    autres_surfaces numeric(15,2),
    surface_autres_terres_boisees numeric(15,2),
    surfaces_non_boisees_naturelles numeric(15,2),
    surfaces_non_boisees_artificialisees numeric(15,2),
    surfaces_non_boisees numeric(15,2),
    precision_surfaces character varying(100),
    type_peuplement real,
    nature character varying(100),
    deces_batimentstouches character varying(100),
    nombre_deces smallint,
    nombre_batiments_totalement_detruits smallint,
    nombre_batiments_partiellement_detruits smallint,
    precision_donnee character varying(200)
);
CREATE INDEX idx_tmp_incendie_insee ON tmp_incendie USING btree (insee);
CREATE INDEX idx_tmp_incendie_nature ON tmp_incendie USING btree (nature);
CREATE INDEX idx_tmp_incendie_precision_surfaces ON tmp_incendie USING btree (precision_surfaces);
CREATE INDEX idx_tmp_incendie_type_peuplement ON tmp_incendie USING btree (type_peuplement);


-------------------------------------------------------------------
--  LOCALISATION
-------------------------------------------------------------------

--
-- Name: localisation; Type: TABLE; Schema: incendies; Owner: -
--
CREATE TABLE localisation (
    id_localisation serial PRIMARY KEY,
    longitude numeric(9,6) NOT NULL,
    latitude numeric(9,6) NOT NULL,
    geom geometry(Point,4326) GENERATED ALWAYS AS (
        st_setsrid(st_makepoint((longitude)::double precision, (latitude)::double precision), 4326)
    ) STORED,
    geom_m geometry(Point,2154) GENERATED ALWAYS AS (
        st_transform(
            st_setsrid(st_makepoint((longitude)::double precision, (latitude)::double precision), 4326), 
            2154
        )
    ) STORED
);
CREATE INDEX idx_localisation_latitude ON localisation USING btree (latitude);
CREATE INDEX idx_localisation_longitude ON localisation USING btree (longitude);
CREATE INDEX localisation_geom_gix ON localisation USING gist (geom);
CREATE INDEX localisation_geom_m_gix ON localisation USING gist (geom_m);


--
-- Name: type_cluster; Type: TABLE; Schema: incendies; Owner: -
--
CREATE TABLE type_cluster (
    id smallserial PRIMARY KEY,
    nom character varying(32)
);

--
-- Name: cluster; Type: TABLE; Schema: incendies; Owner: -
--
CREATE TABLE cluster (
	id_localisation int4 NOT NULL,
	date_experiment timestamp NOT NULL,
	cluster_id varchar(50) NOT NULL,
	type_cluster int2 NOT NULL,
	CONSTRAINT cluster_pkey PRIMARY KEY (id_localisation, date_experiment),
	CONSTRAINT fk_cluster_id_localisation FOREIGN KEY (id_localisation) REFERENCES localisation(id_localisation),
	CONSTRAINT fk_cluster_type_cluster FOREIGN KEY (type_cluster) REFERENCES type_cluster(id)
);


-------------------------------------------------------------------
--  COMMUNES
-------------------------------------------------------------------

--
-- Name: region; Type: TABLE; Schema: incendies; Owner: -
--
CREATE TABLE region (
    id smallserial PRIMARY KEY,
    code smallint,
    nom character varying(32)
);

--
-- Name: departement; Type: TABLE; Schema: incendies; Owner: -
--
CREATE TABLE departement (
    code character varying(10) PRIMARY KEY,
    nom character varying(100)
);

--
-- Name: commune; Type: TABLE; Schema: incendies; Owner: -
--
CREATE TABLE commune (
    id_commune serial PRIMARY KEY,
    code_insee character varying(10),
    localisation integer NOT NULL REFERENCES localisation(id_localisation),
    nom_standard character varying(100),
    region smallint NOT NULL REFERENCES region(id),
    departement character varying(10) REFERENCES departement(code),
    population integer,
    superficie_hectare integer,
    densite numeric(10,2),
    altitude_moyenne smallint,
    altitude_minimale smallint,
    altitude_maximale smallint
);
CREATE INDEX fk_commune_localisation ON commune USING btree (localisation);
CREATE INDEX fk_commune_region ON commune USING btree (region);
CREATE INDEX fk_commune_departement ON commune USING btree (departement);

--
-- Name: experiment; Type: TABLE; Schema: incendies; Owner: -
--
CREATE TABLE experiment (
    id serial PRIMARY KEY,
    date_experiment timestamp without time zone NOT NULL,
    type_cluster smallint NOT NULL REFERENCES type_cluster(id),
    region smallint NOT NULL REFERENCES region(id),
    eps real,
    min_samples integer,
    CONSTRAINT uq_experiment UNIQUE (date_experiment, type_cluster, region)
);


-------------------------------------------------------------------
--  INCENDIES
-------------------------------------------------------------------

--
-- Name: precision_surface; Type: TABLE; Schema: incendies; Owner: -
--
CREATE TABLE precision_surface (
    id smallserial PRIMARY KEY,
    nom character varying(32)
);

--
-- Name: type_peuplement; Type: TABLE; Schema: incendies; Owner: -
--
CREATE TABLE type_peuplement (
    id smallserial PRIMARY KEY,
    nom character varying(32)
);

--
-- Name: nature; Type: TABLE; Schema: incendies; Owner: -
--
CREATE TABLE nature (
    id smallserial PRIMARY KEY,
    nom character varying(32)
);

--
-- Name: incendie; Type: TABLE; Schema: incendies; Owner: -
--
CREATE TABLE incendie (
    id_incendie serial PRIMARY KEY,
    localisation integer NOT NULL REFERENCES localisation(id_localisation),
    code_insee character varying(10) NOT NULL,
    date_premiere_alerte timestamp without time zone NOT NULL,
    annee integer NOT NULL,
    surface_parcourue integer NOT NULL,
    surface_foret integer,
    surface_maquis_garrigues integer,
    autres_surfaces_naturelles integer,
    surfaces_agricoles integer,
    autres_surfaces integer,
    surface_autres_terres_boisees integer,
    surfaces_non_boisees_naturelles integer,
    surfaces_non_boisees_artificialisees integer,
    surfaces_non_boisees integer,
    precision_surface smallint NOT NULL REFERENCES precision_surface(id),
    type_peuplement smallint NOT NULL REFERENCES type_peuplement(id),
    nature smallint NOT NULL REFERENCES nature(id)
);
CREATE INDEX idx_incendie_date_insee ON incendie USING btree (date_premiere_alerte, code_insee);
CREATE INDEX fk_incendie_localisation ON incendie USING btree (localisation);
CREATE INDEX fk_incendie_precision_surface ON incendie USING btree (precision_surface);
CREATE INDEX fk_incendie_type_peuplement ON incendie USING btree (type_peuplement);
CREATE INDEX fk_incendie_nature ON incendie USING btree (nature);


-------------------------------------------------------------------
--  AFFECTE
-------------------------------------------------------------------

--
-- Name: affecte; Type: TABLE; Schema: incendies; Owner: -
--
CREATE TABLE affecte (
    id_commune integer NOT NULL REFERENCES commune(id_commune),
    id_incendie integer NOT NULL REFERENCES incendie(id_incendie),
    date_impact timestamp without time zone NOT NULL,
    degre_impact character varying(50),
    CONSTRAINT pk_affecte PRIMARY KEY (id_commune, id_incendie, date_impact)
);
CREATE INDEX idx_affecte_id_incendie ON affecte USING btree (id_incendie);