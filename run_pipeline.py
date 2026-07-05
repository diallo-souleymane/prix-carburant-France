import os
import subprocess
from pathlib import Path
from dotenv import load_dotenv

load_dotenv()  # injecte .env dans os.environ avant tout appel

from ingestion.api.fetch_fuel_prices import main as ingest

DBT_DIR = Path(__file__).parent / "dbt"


def run_dbt() -> None:
    base = [
        "dbt",
        "--profiles-dir", str(DBT_DIR),
        "--project-dir",  str(DBT_DIR),
    ]
    subprocess.run([*base, "run", "--select", "silver+"], check=True, env=os.environ)
    subprocess.run([*base, "test", "--select", "silver+"], check=True, env=os.environ)


if __name__ == "__main__":
    ingest()
    run_dbt()
