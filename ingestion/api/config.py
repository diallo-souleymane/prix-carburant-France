import os
from dotenv import load_dotenv

load_dotenv()

API_URL = (
    "https://data.economie.gouv.fr/api/explore/v2.1/catalog/datasets"
    "/prix-des-carburants-en-france-flux-instantane-v2/records/"
)
PAGE_SIZE = 100  # limite maximale de l'API v2.1

DB_URI = os.getenv("DB_URI")
if not DB_URI:
    raise EnvironmentError("DB_URI manquant — copier .env.example en .env et renseigner la valeur.")
