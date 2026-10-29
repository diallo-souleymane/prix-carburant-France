# Suivi des prix du carburant en France

Projet Data Engineering — collecte automatisee, transformation et visualisation
des prix du carburant en France via l'API open data du Ministere de l'Economie.

## Architecture Medallion

```
API data.economie.gouv.fr
        │
        ▼  Python (ingestion)
  BRONZE (schema PG)       ← donnees brutes, append-only
        │
        ▼  dbt Core (stg_fuel_prices — incremental)
  SILVER (schema PG)       ← nettoyees, typees, dedoublonnees
        │
        ▼  dbt Core (gold_*)
  GOLD   (schema PG)       ← agregats prets pour Power BI
        │
        ▼
    Power BI
```

## Stack

- **Python** — ingestion API → Bronze (PostgreSQL)
- **dbt Core** — transformations Bronze → Silver → Gold
- **PostgreSQL** — stockage des trois couches
- **Power BI** — visualisation (source : schema Gold)

## Structure du projet

```
prix-carburant-France/
├── ingestion/
│   ├── api/
│   │   ├── fetch_fuel_prices.py   # script principal d'ingestion
│   │   └── config.py              # configuration (API, BDD)
│   └── utils/
│       └── logger.py
├── dbt/
│   ├── dbt_project.yml
│   ├── profiles.yml.example       # a copier dans ~/.dbt/profiles.yml
│   ├── macros/
│   │   └── generate_schema_name.sql
│   └── models/
│       ├── sources.yml            # declaration de la source Bronze
│       ├── silver/
│       │   ├── stg_fuel_prices.sql
│       │   └── schema.yml
│       └── gold/
│           ├── gold_avg_by_region.sql
│           ├── gold_avg_by_fuel.sql
│           ├── gold_price_trend.sql
│           └── schema.yml
├── database/
│   └── init_schemas.sql           # a executer une seule fois
├── .env.example
└── requirements.txt
```

## Installation

```bash
pip install -r requirements.txt
cp .env.example .env    # puis editer .env avec vos identifiants
```

> `dbt/profiles.yml` est lu directement via `--profiles-dir ./dbt` — ne pas copier dans
> `~/.dbt/` pour ne pas ecraser un profil existant (ex. Microsoft Fabric).

## Initialisation de la base

```bash
psql -d prix_carburant -f database/init_schemas.sql
```

## Execution du pipeline

```bash
# Pipeline complet (ingestion + dbt) depuis la racine
python run_pipeline.py
```

Pour lancer dbt seul depuis la CLI :

```bash
# Depuis la racine du projet
dbt --profiles-dir ./dbt --project-dir ./dbt run --select silver+
dbt --profiles-dir ./dbt --project-dir ./dbt test

# OU depuis le dossier dbt/
cd dbt
dbt --profiles-dir . run --select silver+
dbt --profiles-dir . test
```

## Frequence

Pipeline batch execute toutes les 24h.

