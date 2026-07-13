-- Mart: fact table. One row per valid trip.
-- Outliers excluded per documented rules in int_trips_enriched.

with trips as (

    select * from {{ ref('int_trips_enriched') }}
    where not is_outlier

)

select
    -- degenerate dimensions / keys
    pickup_zone_id,
    dropoff_zone_id,
    date(pickup_datetime)           as trip_date,
    extract(hour from pickup_datetime) as pickup_hour,

    -- dimensions
    payment_type,
    rate_code,

    -- facts
    passenger_count,
    trip_distance_miles,
    trip_minutes,
    avg_speed_mph,
    fare_amount,
    tip_amount,
    tip_pct,
    tolls_amount,
    total_amount

from trips
