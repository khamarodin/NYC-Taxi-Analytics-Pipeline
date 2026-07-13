-- Mart: zone dimension (263 TLC zones with borough rollup)

select
    zone_id,
    zone_name,
    borough
from {{ ref('stg_zones') }}
