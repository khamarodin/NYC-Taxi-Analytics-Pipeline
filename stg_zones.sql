-- Staging: taxi zone lookup. Geometry dropped — not needed for BI.

with source as (

    select * from {{ source('nyc_taxi_public', 'taxi_zone_geom') }}

)

select
    cast(zone_id as string)   as zone_id,
    zone_name,
    borough
from source
