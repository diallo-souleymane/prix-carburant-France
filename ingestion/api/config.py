import os
from dotenv import load_dotenv

load_dotenv()

API_URL = "https://data.economie.gouv.fr/api/records/1.0/search/"
DATASET = "prix-des-carburants-en-france-flux-instantane-v2"

DB_URI = os.getenv(
    "DB_URI",
    "postgresql://postgres:Espoir@01@localhost:5432/prix_carburant"
)

BATCH_SIZE = 10000
