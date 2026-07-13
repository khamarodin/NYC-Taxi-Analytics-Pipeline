-- Staging: rename, type-cast, and lightly filter the raw trips.
-- No business logic here — that belongs in intermediate/marts.
--
-- NOTE: column names in the public dataset occasionally differ between years
-- (e.g. rate_code vs RatecodeID). Before first run, preview the table in the
-- BigQuery console or run:
--   SELECT column_name FROM `bigquery-public-data.new_york_taxi_trips`.INFORMATION_SCHEMA.COLUMNS
--   WHERE table_name = 'tlc_yellow_trips_2022';
-- and adjust the names below if needed. Documenting this check in your README
-- is a plus — schema drift between source files is a real-world problem.

with source as (

    select * from {{ source('nyc_taxi_public', 'tlc_yellow_trips_2022') }}

)

select
    -- identifiers & timestamps
    cast(vendor_id as string)               as vendor_id,
    pickup_datetime,
    dropoff_datetime,

    -- trip attributes
    cast(passenger_count as int64)          as passenger_count,
    cast(trip_distance as numeric)          as trip_distance_miles,
    cast(rate_code as string)               as rate_code_id,
    cast(payment_type as string)            as payment_type_id,
    cast(pickup_location_id as string)      as pickup_zone_id,
    cast(dropoff_location_id as string)     as dropoff_zone_id,

    -- money
    cast(fare_amount as numeric)            as fare_amount,
    cast(tip_amount as numeric)             as tip_amount,
    cast(tolls_amount as numeric)           as tolls_amount,
    cast(total_amount as numeric)           as total_amount

from source
where
    -- basic validity filters (documented data-cleaning decisions)
    pickup_datetime is not null
    and dropoff_datetime is not null
    and dropoff_datetime > pickup_datetime
    and extract(year from pickup_datetime) = 2022     -- guard against stray rows
