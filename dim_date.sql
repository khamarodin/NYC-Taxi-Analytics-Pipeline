-- Mart: date dimension for 2022, generated in SQL (no source table needed)

with dates as (

    select d as date_day
    from unnest(generate_date_array('2022-01-01', '2022-12-31')) as d

)

select
    date_day,
    extract(year from date_day)                 as year,
    extract(month from date_day)                as month,
    format_date('%b %Y', date_day)              as month_name,
    extract(dayofweek from date_day)            as day_of_week_num,   -- 1=Sun
    format_date('%A', date_day)                 as day_name,
    extract(dayofweek from date_day) in (1, 7)  as is_weekend
from dates
