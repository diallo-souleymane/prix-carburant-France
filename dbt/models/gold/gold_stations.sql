-- models/gold/gold_stations.sql
--
-- GOLD : une ligne = une station x un carburant, avec coordonnees GPS,
-- prix et statut. C'est la table consommee par la CARTE Power BI
-- (points colores selon disponibilite / rupture).

{{ config(materialized='table', schema='gold') }}

select
    station_id,
    carburant,
    prix,
    statut,
    -- indicateur binaire pratique pour colorer la carte
    case
        when statut = 'disponible' then 1
        else 0
    end as est_disponible,
    -- libelle court pour les infobulles
    case
        when statut = 'disponible'         then 'Disponible'
        when statut = 'rupture_temporaire' then 'Rupture temporaire'
        when statut = 'rupture_definitive' then 'Rupture definitive'
        else 'Non propose'
    end as statut_libelle,
    prix_maj,
    adresse,
    ville,
    cp,
    departement,
    region,
    latitude,
    longitude
from {{ ref('stg_fuel_prices') }}
-- on garde les carburants reellement proposes (disponibles ou en rupture),
-- on exclut ceux jamais proposes par la station
where statut <> 'non_propose'