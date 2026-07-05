-- models/gold/gold_avg_by_region.sql
--
-- GOLD : prix moyen par region et par carburant.
-- Source pour la carte choroplethe et les comparaisons regionales (Power BI).

{{ config(materialized='table', schema='gold') }}

select
    region,
    code_region,
    carburant,
    round(avg(prix), 3)   as prix_moyen,
    round(min(prix), 3)   as prix_min,
    round(max(prix), 3)   as prix_max,
    count(*)              as nb_stations
from {{ ref('stg_fuel_prices') }}
where prix is not null
  and statut = 'disponible'
  and region is not null
group by region, code_region, carburant