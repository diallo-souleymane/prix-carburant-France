import requests
import pandas as pd
from sqlalchemy import create_engine
from datetime import datetime

from config import API_URL, DATASET, DB_URI, BATCH_SIZE
from ingestion.utils.logger import get_logger

logger = get_logger("fuel_ingestion")


def fetch_data():
    logger.info("Appel API des prix du carburant")
    params = {
        "dataset": DATASET,
        "rows": BATCH_SIZE,
    }
    response = requests.get(API_URL, params=params)
    response.raise_for_status()
    return response.json()["records"]


def normalize_data(records):
    logger.info("Normalisation des données JSON")
    df = pd.json_normalize(records)

    df = df.rename(columns={
        "fields.id": "station_id",
        "fields.adresse": "adresse",
        "fields.region": "region",
        "fields.prix": "prix",
        "fields.carburant": "carburant",
        "fields.horaires_jour": "date_maj"
    })

    df = df[
        ["station_id", "adresse", "region",
         "carburant", "prix", "date_maj"]
    ]

    df["source"] = "API"
    df["date_ingestion"] = datetime.utcnow()

    return df


def load_to_raw(df):
    logger.info("Chargement des données en zone RAW")
    engine = create_engine(DB_URI)

    df.to_sql(
        "raw_fuel_prices",
        engine,
        if_exists="append",
        index=False
    )


def main():
    records = fetch_data()
    df = normalize_data(records)
    load_to_raw(df)
    logger.info("Ingestion terminée avec succès")


if __name__ == "__main__":
    main()