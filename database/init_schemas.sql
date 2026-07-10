-- Initialisation des schemas Medallion Architecture
-- A executer une seule fois sur la base prix_carburant_france

CREATE SCHEMA IF NOT EXISTS bronze;
CREATE SCHEMA IF NOT EXISTS silver;
CREATE SCHEMA IF NOT EXISTS gold;

-- BRONZE : donnees brutes, append-only, jamais modifiees
-- Format large : une ligne = une station, un ingested_at par run.
-- Doit rester en phase avec flatten() dans ingestion/api/fetch_fuel_prices.py
CREATE TABLE IF NOT EXISTS bronze.fuel_prices_raw (
    station_id         VARCHAR(50),
    adresse             TEXT,
    ville               VARCHAR(100),
    cp                  VARCHAR(10),
    departement         VARCHAR(100),
    code_departement    VARCHAR(10),
    region              VARCHAR(100),
    code_region         VARCHAR(10),
    latitude            NUMERIC(10, 6),
    longitude           NUMERIC(10, 6),

    gazole_prix         NUMERIC(6, 3),
    gazole_maj          TIMESTAMP,
    gazole_rupture_type VARCHAR(20),
    gazole_statut       VARCHAR(20),

    sp95_prix           NUMERIC(6, 3),
    sp95_maj            TIMESTAMP,
    sp95_rupture_type   VARCHAR(20),
    sp95_statut         VARCHAR(20),

    sp98_prix           NUMERIC(6, 3),
    sp98_maj            TIMESTAMP,
    sp98_rupture_type   VARCHAR(20),
    sp98_statut         VARCHAR(20),

    e10_prix            NUMERIC(6, 3),
    e10_maj             TIMESTAMP,
    e10_rupture_type    VARCHAR(20),
    e10_statut          VARCHAR(20),

    e85_prix            NUMERIC(6, 3),
    e85_maj             TIMESTAMP,
    e85_rupture_type    VARCHAR(20),
    e85_statut          VARCHAR(20),

    gplc_prix           NUMERIC(6, 3),
    gplc_maj            TIMESTAMP,
    gplc_rupture_type   VARCHAR(20),
    gplc_statut         VARCHAR(20),

    ingested_at         TIMESTAMP
);
