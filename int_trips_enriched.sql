-- Intermediate: business logic layer.
-- Decodes coded fields, computes derived metrics, applies outlier rules.
-- Every rule here is a documented, defensible analytical decision.

with trips as (

    select * from {{ ref('stg_trips') }}

)

select
    *,

    -- decode payment type (TLC data dictionary)
    case payment_type_id
        when '1' then 'Credit card'
        when '2' then 'Cash'
        when '3' then 'No charge'
        when '4' then 'Dispute'
        else 'Other/Unknown'
    end as payment_type,

    -- decode rate code
    case rate_code_id
        when '1' then 'Standard'
        when '2' then 'JFK'
        when '3' then 'Newark'
        when '4' then 'Nassau/Westchester'
        when '5' then 'Negotiated'
        when '6' then 'Group ride'
        else 'Unknown'
    end as rate_code,

    -- derived metrics
    timestamp_diff(dropoff_datetime, pickup_datetime, minute) as trip_minutes,

    safe_divide(
        trip_distance_miles,
        timestamp_diff(dropoff_datetime, pickup_datetime, second) / 3600.0
    ) as avg_speed_mph,

    safe_divide(tip_amount, nullif(fare_amount, 0)) as tip_pct,

    -- outlier flag (kept as a flag, NOT deleted — analysts can decide;
    -- fct_trips filters on it and the choice is documented in the README)
    case
        when trip_distance_miles <= 0 or trip_distance_miles > 100 then true
        when timestamp_diff(dropoff_datetime, pickup_datetime, minute) > 240 then true
        when total_amount <= 0 or total_amount > 500 then true
        when safe_divide(trip_distance_miles,
             timestamp_diff(dropoff_datetime, pickup_datetime, second) / 3600.0) > 80 then true
        else false
    end as is_outlier

from trips
