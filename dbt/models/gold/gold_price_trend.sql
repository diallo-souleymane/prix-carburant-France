-- models/gold/gold_price_trend.sql
--
-- GOLD : evolution temporelle du prix moyen national par carburant.
-- Une ligne = un jour x un carburant.
--
-- IMPORTANT : ce modele s'appuie sur la date de mise a jour du prix (prix_maj)
-- agregee par jour. Pour un vrai suivi historique, il se construit en
-- INCREMENTAL afin d'empiler les points dans le temps a chaque execution
-- quotidienne du pipeline.

{{
  config(
    materialized='incremental',
    unique_key=['jour', 'carburant'],
    schema='gold'
  )
}}

with base as (

    select
        carburant,
        date(prix_maj) as jour,
        prix
    from {{ ref('stg_fuel_prices') }}
    where prix is not null
      and statut = 'disponible'
      and prix_maj is not null

    {% if is_incremental() %}
    -- ne recalculer que les jours recents
    and date(prix_maj) >= (select coalesce(max(jour), '1900-01-01') from {{ this }})
    {% endif %}

)

select
    jour,
    carburant,
    round(avg(prix), 3) as prix_moyen,
    count(*)            as nb_releves
from base
group by jour, carburant