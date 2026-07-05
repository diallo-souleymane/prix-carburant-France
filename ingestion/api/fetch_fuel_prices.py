"""
Ingestion des prix du carburant (API open data data.economie.gouv.fr)
vers la couche Bronze (MySQL).

- Pagination complete de l'API (limit 100 par page)
- Aplatissement des champs utiles : prix, statut et coordonnees GPS par station
- Ecriture en mode append dans bronze.fuel_prices_raw
- Horodatage de l'ingestion (ingested_at) pour le suivi incremental
"""

import os
import sys
import logging
from datetime import datetime, timezone

import concurrent.futures

import requests
import pandas as pd
from sqlalchemy import create_engine
from dotenv import load_dotenv
import time
# ----------------------------------------------------------------------
# Configuration
# ----------------------------------------------------------------------
load_dotenv()

DB_URI = os.getenv("DB_URI")  # mysql+pymysql://user:pwd@127.0.0.1:3306/bronze
if not DB_URI:
    sys.exit("Variable DB_URI manquante dans le fichier .env")

API_URL = (
    "https://data.economie.gouv.fr/api/explore/v2.1/catalog/datasets/"
    "prix-des-carburants-en-france-flux-instantane-v2/records"
)
PAGE_SIZE = 100              # max autorise par l'API
TABLE_NAME = "fuel_prices_raw"
REQUEST_TIMEOUT = 30         # secondes

# Liste des carburants suivis (champs aplatis fournis par l'API)
FUELS = ["gazole", "sp95", "sp98", "e10", "e85", "gplc"]

# ----------------------------------------------------------------------
# Logging
# ----------------------------------------------------------------------
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
log = logging.getLogger("ingestion")


# ----------------------------------------------------------------------
# Extraction
# ----------------------------------------------------------------------
# Remplacez la fonction fetch_all_records() existante par celle-ci,
# et changez REQUEST_TIMEOUT = 90 en haut du fichier.

MAX_RETRIES = 3
MAX_WORKERS = 10  # requetes paralleles vers l'API


def _fetch_page(offset: int) -> list:
    """Recupere une page de l'API avec reessais exponentiels."""
    params = {"limit": PAGE_SIZE, "offset": offset, "lang": "fr"}
    for attempt in range(1, MAX_RETRIES + 1):
        try:
            resp = requests.get(API_URL, params=params, timeout=REQUEST_TIMEOUT)
            resp.raise_for_status()
            return resp.json().get("results", [])
        except requests.RequestException as exc:
            log.warning("Tentative %s/%s echouee (offset=%s) : %s",
                        attempt, MAX_RETRIES, offset, exc)
            if attempt < MAX_RETRIES:
                wait = attempt * 10
                log.info("Nouvelle tentative dans %s secondes...", wait)
                time.sleep(wait)
            else:
                log.error("Echec definitif apres %s tentatives (offset=%s)",
                          MAX_RETRIES, offset)
                raise


def fetch_all_records() -> list:
    """Recupere tous les enregistrements via pagination parallele."""
    # Premiere requete pour connaitre le total et recuperer la page 0
    first_batch = _fetch_page(0)
    if not first_batch:
        return []

    # Une seconde requete legere pour lire total_count
    resp = requests.get(API_URL, params={"limit": 1, "offset": 0}, timeout=REQUEST_TIMEOUT)
    resp.raise_for_status()
    total = resp.json().get("total_count", 0)
    log.info("Total stations annoncees par l'API : %s", total)

    remaining_offsets = list(range(PAGE_SIZE, total, PAGE_SIZE))
    records = list(first_batch)

    with concurrent.futures.ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
        futures = {executor.submit(_fetch_page, off): off for off in remaining_offsets}
        for future in concurrent.futures.as_completed(futures):
            records.extend(future.result())
            log.info("Recupere %s / %s", len(records), total)

    return records


# ----------------------------------------------------------------------
# Transformation (aplatissement)
# ----------------------------------------------------------------------
def flatten(record):
    """Transforme un enregistrement brut API en une ligne plate exploitable."""
    geom = record.get("geom") or {}
    disponibles = record.get("carburants_disponibles") or []

    row = {
        "station_id": record.get("id"),
        "adresse": record.get("adresse"),
        "ville": record.get("ville"),
        "cp": record.get("cp"),
        "departement": record.get("departement"),
        "code_departement": record.get("code_departement"),
        "region": record.get("region"),
        "code_region": record.get("code_region"),
        # Coordonnees GPS standard (WGS84) issues de geom, exploitables par Power BI
        "latitude": geom.get("lat"),
        "longitude": geom.get("lon"),
    }

    # Pour chaque carburant : prix, date maj, type de rupture, statut
    for fuel in FUELS:
        prix = record.get(f"{fuel}_prix")
        rupture_type = record.get(f"{fuel}_rupture_type")  # temporaire / definitive / None

        row[f"{fuel}_prix"] = prix
        row[f"{fuel}_maj"] = record.get(f"{fuel}_maj")
        row[f"{fuel}_rupture_type"] = rupture_type

        # Statut lisible pour la couche viz
        fuel_label = {
            "gazole": "Gazole", "sp95": "SP95", "sp98": "SP98",
            "e10": "E10", "e85": "E85", "gplc": "GPLc",
        }[fuel]
        if fuel_label in disponibles:
            statut = "disponible"
        elif rupture_type:
            statut = f"rupture_{rupture_type}"
        else:
            statut = "non_propose"
        row[f"{fuel}_statut"] = statut

    return row


# ----------------------------------------------------------------------
# Chargement
# ----------------------------------------------------------------------
def load_to_bronze(df):
    """Ecrit le DataFrame dans MySQL (append)."""
    engine = create_engine(DB_URI)
    df.to_sql(
        TABLE_NAME,
        con=engine,
        if_exists="append",   # append-only : on conserve l'historique
        index=False,
        chunksize=500,
        method="multi",
    )
    engine.dispose()


# ----------------------------------------------------------------------
# Pipeline
# ----------------------------------------------------------------------
def main():
    log.info("=== Demarrage ingestion prix carburant -> Bronze (MySQL) ===")

    records = fetch_all_records()
    if not records:
        log.warning("Aucun enregistrement recupere. Arret.")
        return

    rows = [flatten(r) for r in records]
    df = pd.DataFrame(rows)

    # Horodatage de l'ingestion (cle pour le mode incremental cote dbt)
    df["ingested_at"] = datetime.now(timezone.utc)

    log.info("Lignes preparees : %s (colonnes : %s)", len(df), len(df.columns))

    load_to_bronze(df)
    log.info("=== Ingestion terminee : %s lignes inserees dans bronze.%s ===",
             len(df), TABLE_NAME)


if __name__ == "__main__":
    main()