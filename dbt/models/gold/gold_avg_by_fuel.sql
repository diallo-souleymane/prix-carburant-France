-- models/gold/gold_avg_by_fuel.sql
--
-- GOLD : prix moyen national par type de carburant.
-- Source pour les cartes KPI (Power BI).

{{ config(materialized='table', schema='gold') }}

select
    carburant,
    round(avg(prix), 3)   as prix_moyen_national,
    round(min(prix), 3)   as prix_min,
    round(max(prix), 3)   as prix_max,
    count(*)              as nb_stations
from {{ ref('stg_fuel_prices') }}
where prix is not null
  and statut = 'disponible'
group by carburant
order by carburant