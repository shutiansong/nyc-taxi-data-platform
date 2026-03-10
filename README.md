# NYC Taxi Data Platform

A production-style **batch ELT data platform** built to process NYC Taxi trip datasets using a containerized data stack.

The project focuses on **deterministic batch processing, explicit data quality signaling, and safe pipeline reruns**, simulating operational patterns commonly used in real-world data platforms.

---

# Architecture Overview

![Architecture](screenshots/pipeline_architecture.png)

Pipeline flow:

Raw Parquet Data (Monthly)  
↓  
Spark Batch ELT (DQ validation + classification)  
↓  
PostgreSQL Warehouse  
↓  
dbt Transformation Layer  
↓  
Metabase Analytics Dashboards  

All components run as isolated containers orchestrated with Docker Compose.

---

# Key Features

- Deterministic **monthly batch processing (batch-id = YYYY-MM)**
- **Safe reruns and historical backfills**
- Explicit **data quality classification** (clean / suspicious / critical)
- **Quarantine tables** preserving anomalous records instead of silent filtering
- **Partition-aware dbt validation** for scalable testing
- **Operational metadata logging** for ingestion observability
- Fully **containerized local data platform**

---

# Pipeline Orchestration

The pipeline is orchestrated using **Airflow**, coordinating ingestion, validation, transformation, and analytics workflows.

Example DAG structure:

![Airflow DAG](screenshots/airflow_dag.png)

---

# dbt Transformation Lineage

The transformation layer follows a **staging → intermediate → analytics** modeling architecture.

Key transformations include:

- trip deduplication
- derived metrics
- data quality signals
- dimensional modeling
- aggregated analytics

![dbt Lineage](screenshots/dbt_lineage.png)

---

# Analytics Dashboards

Dashboards built with **Metabase** provide insights including:

- trip volume and revenue
- vendor performance trends
- payment type distribution
- pickup zone spatial analytics

![Metabase Dashboard](screenshots/metabase_dashboard.png)

---

# Technology Stack

| Layer | Technology |
|------|------|
| Orchestration | Airflow |
| Processing | Spark (PySpark) |
| Warehouse | PostgreSQL |
| Transformation | dbt |
| BI / Visualization | Metabase |
| Infrastructure | Docker Compose |
| Data Source | NYC Yellow Taxi Trip Data |

---

# Batch Semantics & Determinism

The pipeline processes data in **monthly batches (YYYY-MM)**.

Each batch is:

- ingested and validated by Spark
- persisted into warehouse tables
- transformed and tested via dbt

### Safe reruns

Pipeline reruns fully replace the batch snapshot, preventing partial updates and ensuring deterministic results.

### Late / Early Trip Handling

Trips outside the expected batch window are classified as:

| Category | Handling |
|------|------|
| Clean | Base table |
| Suspicious | Base + Quarantine |
| Critical | Quarantine only |

This design preserves anomalous records for auditability.

---

# Raw ELT Layer (Spark)

The ingestion layer focuses on:

- deterministic batch processing
- centralized data quality validation
- rerun-safe loading
- ingestion observability

### Processing Steps

1. Download monthly Parquet files
2. Spark reads and validates records
3. Data quality rules classify trips
4. Results written to PostgreSQL warehouse tables

### Rerun-safe loading strategy

Raw tables use:

partition + truncate + rewrite

This avoids table bloat during reruns and guarantees deterministic batch snapshots.

---

# Metadata & Observability

Operational metadata is stored in:

metadata.batch_ingestion_stats

Captured metrics include:

- input row count
- base / quarantine row counts
- anomaly distribution
- pickup timestamp ranges

These metrics enable auditing, debugging, and operational monitoring.

---

# dbt Transformation Layer

dbt builds analytics-ready models on top of Spark-processed data.

### Staging Layer

- standardized column naming
- stable interface over raw tables

### Intermediate Layer

Includes transformations such as:

- trip deduplication
- metric derivation
- data quality signals

Example models:

int_ny_taxi_trips_dedup
int_ny_taxi_trips_metrics
int_ny_taxi_trips_dq

### Dimension Tables

dim_vendor
dim_rate_code
dim_payment_type
dim_zones

### Fact Tables

fct_trips_wide
fct_trips_daily_vendor
fct_trips_daily_pickup_zone
fct_trips_daily_payment_type

---

# Incremental Strategy

dbt models use **incremental materialization with partition filtering**.

Benefits:

- reruns only affect target partitions
- avoids full-table rebuilds
- improves validation performance

Example improvement:

dbt test runtime
15 minutes → 8–9 minutes


---

# Performance Optimizations

Key optimizations implemented in the pipeline:

- Partition-aware dbt tests prevent full-table scans
- Raw ingestion uses truncate + rewrite to avoid table bloat
- Containerized tmp usage prevents disk accumulation
- PostgreSQL extend storage reduced from ~100GB to <50MB

---

# Design Principles

| Principle | Implementation |
|------|------|
| Correctness over throughput | Batch processing (~15 min per batch) |
| Deterministic ELT snapshots | Partition + truncate + rewrite |
| Explicit data quality signaling | DQ flags instead of filtering |
| Layer separation | Spark ingestion vs dbt analytics |

---

# Lessons Learned

Key engineering insights from building this project:

- Late-arriving data requires explicit classification strategies
- Partitioning dramatically improves rerun performance
- Observability is critical for debugging batch pipelines
- Separating ingestion and transformation layers improves maintainability
