import os
from dotenv import load_dotenv

load_dotenv()

API_URL = "https://data.economie.gouv.fr/api/records/1.0/search/"
DATASET = "prix-des-carburants-en-france-flux-instantane-v2"

DB_URI = os.getenv(
    "DB_URI",
    "postgresql://user:password@localhost:5432/fuel_db"
)

BATCH_SIZE = 10000