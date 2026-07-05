-- Initialisation des schemas Medallion Architecture
-- A executer une seule fois sur la base prix_carburant

CREATE SCHEMA IF NOT EXISTS bronze;
CREATE SCHEMA IF NOT EXISTS silver;
CREATE SCHEMA IF NOT EXISTS gold;

-- BRONZE : donnees brutes, append-only, jamais modifiees
CREATE TABLE IF NOT EXISTS bronze.fuel_prices_raw (
    station_id     VARCHAR(50),
    adresse        TEXT,
    ville          VARCHAR(100),
    code_postal    VARCHAR(10),
    region         VARCHAR(100),
    carburant      VARCHAR(50),
    prix           NUMERIC(6,3),
    date_maj       DATE,
    source         VARCHAR(10),
    date_ingestion TIMESTAMP
);
