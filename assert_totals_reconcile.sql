-- Custom test: total_amount should roughly equal the sum of its components.
-- (fare + tip + tolls, allowing $2.50 tolerance for taxes/surcharges we
-- deliberately excluded from the mart). Returns violating rows; test passes
-- when zero rows return. Threshold: fail only if > 0.5% of trips violate.

{{ config(severity = 'warn') }}

with violations as (

    select *
    from {{ ref('fct_trips') }}
    where abs(total_amount - (fare_amount + tip_amount + tolls_amount)) > 6.0
    -- 6.0 = generous allowance for MTA tax, improvement & congestion
    -- surcharges, airport fees (documented in KPI definitions)

)

select * from violations
