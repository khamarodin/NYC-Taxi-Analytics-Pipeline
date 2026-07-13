# NYC-Taxi-Analytics-Pipeline

Business Question

Where and when does NYC yellow-cab demand concentrate, how do rider payment behaviors differ, and what operational patterns (congestion, tipping, borough economics) should a fleet operator act on?

Technology Stack

LayerTechnologyWhySource dataNYC TLC Trip Records (BigQuery public dataset, ~36M trips, 2022)Real production-scale data; hosted raw layer means the source is immutable and reproducible by anyoneWarehouseGoogle BigQuery (sandbox)Serverless cloud warehouse; staging built as views = zero storage costTransformationdbt Core 1.11Version-controlled SQL models, dependency-aware builds, automated testing, generated documentation & lineageModeling patternStar schema (1 fact, 2 dimensions)BI-optimized: fast aggregation, intuitive joins, single source of truth for metricsBI / VisualizationTableau PublicInteractive published dashboard; free tier constraint (no live BigQuery connection) handled via a deliberately designed aggregate extractAuth & toolinggcloud CLI (ADC oauth), Git, PowerShellCredentials stored outside the repo; never committed

Architecture

bigquery-public-data.new_york_taxi_trips          RAW (read in place, never copied)
        │
        ▼  dbt STAGING (views): rename, type-cast, validity filters
   stg_trips ── stg_zones
        │
        ▼  dbt INTERMEDIATE (view): decode coded fields, derive metrics, flag outliers
   int_trips_enriched
        │
        ▼  dbt MARTS (tables): star schema
   fct_trips ─── dim_zones ─── dim_date
        │
        ▼  aggregated extract (day × hour × borough × payment grain)
   Tableau Public dashboard

(Insert dbt docs lineage DAG screenshot here — generated with dbt docs generate)

Pipeline, Step by Step

1. Raw layer — untouched by design

Staging models are views over the public dataset; the raw data is never copied or modified. This guarantees reproducibility (anyone can rerun against the identical source), costs zero storage, and preserves a complete audit trail from any dashboard number back to source rows.

2. Staging (models/staging/)

stg_trips and stg_zones do only mechanical work: consistent naming, type casting, and basic validity filters (non-null timestamps, dropoff after pickup). No business logic lives here — schema drift in the source is absorbed by this single layer.

3. Intermediate (models/intermediate/)

int_trips_enriched holds the business logic: decoding TLC payment/rate codes into readable labels, deriving trip duration, average speed, and tip percentage, and flagging outliers (impossible speeds, negative fares, >4-hour trips) rather than silently deleting them — the exclusion rate (~1–2%) is measurable and documented.

4. Marts (models/marts/)

The star schema BI connects to: fct_trips (one row per valid trip), dim_zones (263 TLC zones with borough rollup), dim_date (calendar generated in SQL — no source table needed). Materialized as tables for query speed.

5. Data quality — 15 automated tests

dbt test runs schema tests (not_null, unique, accepted_values, fact→dimension referential integrity) plus a custom reconciliation test asserting total_amount ≈ fare + tip + tolls within a documented surcharge tolerance. Referential and reconciliation tests are set to warn severity deliberately: a small number of trips reference retired zone IDs — a documented data reality, not a pipeline bug.

6. Semantic layer

Every dashboard metric has a written definition in docs/kpi_definitions.md, including grain statements and known limitations — e.g., cash tips are not recorded in TLC data, so tip metrics are credit-card-biased and labeled as such on the dashboard.

7. BI extract — a deliberate modeling decision

Tableau Public cannot connect live to BigQuery, and the 36M-row fact table exceeds local extract limits (BigQuery's local CSV export silently truncates at ~16K rows — discovered and fixed during development). The solution: an aggregate extract at exactly the dashboard's grain (day × hour × borough × payment type), plus a small zone-level extract for zone rankings. Full totals in Tableau reconcile to warehouse SQL.

8. Dashboard (Tableau Public)


Page 1 — City Pulse: KPI row (trips, revenue, avg fare, tip %), hour × weekday demand heatmap, daily trend with weekend highlighting, borough revenue
Page 2 — Zone Economics: top pickup zones by revenue, tip % by borough and payment type, average speed by hour (congestion)
