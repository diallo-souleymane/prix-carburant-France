DROP TABLE IF EXISTS raw_fuel_prices;
CREATE TABLE raw_fuel_prices (
    station_id VARCHAR(50),
    adresse TEXT,
    region VARCHAR(100),
    carburant VARCHAR(50),
    prix NUMERIC(5,3),
    date_maj DATE,
    source VARCHAR(10),
    date_ingestion TIMESTAMP
);