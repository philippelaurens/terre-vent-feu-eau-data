CREATE EXTENSION IF NOT EXISTS postgis SCHEMA public;

CREATE SCHEMA IF NOT EXISTS incendies AUTHORIZATION gis_app;

-- Configuration du rôle pour qu'il cherche TOUJOURS dans incendies puis public
ALTER ROLE gis_app SET search_path TO incendies, public;

-- Application du search_path pour la session courante
SET search_path TO incendies, public;
