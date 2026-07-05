-- models/silver/stg_fuel_prices.sql
--
-- Couche SILVER : nettoyage, typage, depivotage et dedoublonnage.
-- Format LONG : une ligne = une station x un carburant.
--
-- Source : bronze.fuel_prices_raw (append-only, plusieurs ingestions empilees)
-- Strategie : on ne garde que la DERNIERE ingestion par station, puis on
-- depivote les 6 carburants en lignes.

{{
  config(
    materialized='incremental',
    incremental_strategy='delete+insert',
    unique_key=['station_id', 'carburant'],
    schema='silver'
  )
}}

with source as (

    select *
    from {{ source('bronze', 'fuel_prices_raw') }}

    {% if is_incremental() %}
    -- En incremental : ne traiter que les ingestions plus recentes
    where ingested_at > (select coalesce(max(ingested_at), '1900-01-01') from {{ this }})
    {% endif %}

),

-- On ne conserve que la derniere ingestion connue par station
derniere_ingestion as (

    select
        *,
        row_number() over (
            partition by station_id
            order by ingested_at desc
        ) as rn
    from source

),

stations as (

    select
        station_id,
        adresse,
        ville,
        cp,
        departement,
        code_departement,
        region,
        code_region,
        cast(latitude  as decimal(10, 6)) as latitude,
        cast(longitude as decimal(10, 6)) as longitude,
        ingested_at,
        -- prix
        cast(gazole_prix as decimal(6, 3)) as gazole_prix,
        cast(sp95_prix   as decimal(6, 3)) as sp95_prix,
        cast(sp98_prix   as decimal(6, 3)) as sp98_prix,
        cast(e10_prix    as decimal(6, 3)) as e10_prix,
        cast(e85_prix    as decimal(6, 3)) as e85_prix,
        cast(gplc_prix   as decimal(6, 3)) as gplc_prix,
        -- dates maj
        gazole_maj, sp95_maj, sp98_maj, e10_maj, e85_maj, gplc_maj,
        -- statuts
        gazole_statut, sp95_statut, sp98_statut, e10_statut, e85_statut, gplc_statut
    from derniere_ingestion
    where rn = 1
      and latitude is not null
      and longitude is not null

),

-- Depivotage : 6 carburants -> 6 lignes par station (via UNION ALL)
depivote as (

    select station_id, 'Gazole' as carburant,
           gazole_prix as prix, gazole_maj as prix_maj, gazole_statut as statut
    from stations
    union all
    select station_id, 'SP95',  sp95_prix, sp95_maj, sp95_statut from stations
    union all
    select station_id, 'SP98',  sp98_prix, sp98_maj, sp98_statut from stations
    union all
    select station_id, 'E10',   e10_prix,  e10_maj,  e10_statut  from stations
    union all
    select station_id, 'E85',   e85_prix,  e85_maj,  e85_statut  from stations
    union all
    select station_id, 'GPLc',  gplc_prix, gplc_maj, gplc_statut from stations

),

final as (

    select
        d.station_id,
        d.carburant,
        d.prix,
        cast(d.prix_maj as datetime) as prix_maj,
        d.statut,
        -- on enrichit chaque ligne avec les attributs de la station
        s.adresse,
        s.ville,
        s.cp,
        s.departement,
        s.code_departement,
        s.region,
        s.code_region,
        s.latitude,
        s.longitude,
        s.ingested_at
    from depivote d
    inner join stations s on d.station_id = s.station_id

)

select *
from final
-- On exclut les lignes sans prix (carburants non proposes par la station)
where prix is not null