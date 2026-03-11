# NYC Taxi Data Platform

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE) 
[![Repo Size](https://img.shields.io/github/repo-size/shutiansong/nyc-taxi-data-platform)](https://github.com/shutiansong/nyc-taxi-data-platform)
[![Last Commit](https://img.shields.io/github/last-commit/shutiansong/nyc-taxi-data-platform)](https://github.com/shutiansong/nyc-taxi-data-platform)

[![Docker](https://img.shields.io/badge/Docker-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![Airflow](https://img.shields.io/badge/Airflow-017CEE?logo=apacheairflow&logoColor=white)](https://airflow.apache.org/)
[![Spark](https://img.shields.io/badge/Spark-E25A1C?logo=apachespark&logoColor=white)](https://spark.apache.org/)
[![dbt](https://img.shields.io/badge/dbt-FF694B?logo=dbt&logoColor=white)](https://www.getdbt.com/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-336791?logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![Metabase](https://img.shields.io/badge/Metabase-509EE3?logo=metabase&logoColor=white)](https://www.metabase.com/)

![Pipeline](https://img.shields.io/badge/Pipeline-Batch-blue)
![ELT](https://img.shields.io/badge/ELT-Idempotent-orange)
![Data Quality](https://img.shields.io/badge/Data%20Quality-Validated-green)
![Processing](https://img.shields.io/badge/Processing-Partitioned-purple)
![Warehouse](https://img.shields.io/badge/Warehouse-PostgreSQL-blue)
![Infrastructure](https://img.shields.io/badge/Infra-Dockerized-2496ED)
![Processing Model](https://img.shields.io/badge/Processing-Deterministic-red)

A production-grade **batch ELT data platform** for NYC Taxi trip datasets, emphasizing **deterministic batch processing, explicit data quality signaling, and safe reruns**. Fully **containerized** for reproducibility and modular orchestration.

---

# Table of Contents

1. [Architecture Overview](#architecture-overview)  
2. [Technology Stack](#technology-stack)  
3. [Pipeline Flow](#pipeline-flow)  
4. [Raw ELT Layer (Spark)](#raw-elt-layer-spark)  
5. [dbt Transformation Layer](#dbt-transformation-layer)  
6. [Analytics Dashboards](#analytics-dashboards-metabase)  
7. [Batch Semantics & Determinism](#batch-semantics--determinism)  
8. [Design Principles](#design-principles)  
9. [Lessons Learned](#lessons-learned)  
10. [Summary](#summary)

---

# Architecture Overview

<p align="center">
  <img src="screenshots/pipeline_architecture.png" width="850">
</p>

**Pipeline Flow:**

Raw Parquet Data (Monthly) → Spark Batch ELT → PostgreSQL Warehouse → dbt Transformation → Metabase Dashboards

All components run as isolated **Docker containers** orchestrated via **Docker Compose**, ensuring reproducibility, modularity, and safe local deployment.

---

# Technology Stack

| Layer | Technology |
|-------|------------|
| Orchestration | Airflow (PythonOperator, BashOperator, DockerOperator) |
| Processing | Spark (PySpark) |
| Warehouse | PostgreSQL |
| Transformation | dbt |
| BI / Visualization | Metabase |
| Infrastructure | Docker Compose |
| Data Source | NYC Yellow Taxi Trip Data (monthly Parquet) |

---

# Pipeline Flow

1. **Raw Parquet Data (Monthly)**: ingested from source  
2. **Spark Batch ELT**: deterministic ingestion, DQ validation, classification into clean / suspicious / critical  
3. **PostgreSQL Warehouse**: stores base and quarantine tables; partition + truncate + rewrite for rerun-safe snapshots; metadata logging  
4. **dbt Transformation Layer**: staging → intermediate → analytics; deduplication, metrics, DQ signals, dimensional modeling  
5. **Metabase Dashboards**: trip counts, revenue, vendor performance, payment mix, pickup-zone spatial analysis  

---

# Pipeline Orchestration (Airflow)

Airflow orchestrates the full batch pipeline, coordinating ingestion, transformation, and validation tasks.

Key responsibilities include:

- batch scheduling  
- dependency management  
- safe pipeline reruns  
- operational monitoring  

Example DAG structure:

<p align="center">
  <img src="screenshots/airflow_dag.png" width="850">
</p>

---

# Raw ELT Layer (Spark)

The Spark layer handles:

- Deterministic ingestion scoped by batch-id (YYYY-MM)  
- Centralized data quality validation: time, pricing, passenger anomalies  
- Classification: clean → base, suspicious → base + quarantine, critical → quarantine  

**Rerun-safe loading strategy:**

- `partition + truncate + rewrite` prevents table bloat and guarantees deterministic batch snapshots  

**Metadata & Observability:**

- Input / output row counts (base/quarantine)  
- DQ issue distribution  
- Pickup timestamp ranges  
- Stored in `metadata.batch_ingestion_stats` for auditing and SLA monitoring  

---

# dbt Transformation Layer

dbt builds analytics-ready models on top of Spark-processed data.

### Staging Layer

- Standardizes column naming  
- Provides stable interface over raw tables  

### Intermediate Layer

- Trip deduplication  
- Metric derivation  
- Data quality signals  

### Dimension Tables

- dim_vendor, dim_rate_code, dim_payment_type, dim_zones  

### Fact Tables

- fct_trips_wide  
- fct_trips_daily_vendor  
- fct_trips_daily_pickup_zone  
- fct_trips_daily_payment_type  

**Incremental & Partitioning Strategy:**

- Incremental materialization scoped by `pickup_month`  
- Only affects current partition for reruns  
- Partition-aware dbt tests improve performance (~15 → 8–9 min)  
- Extend storage reduced from ~100GB → <50MB  

<p align="center">
  <img src="screenshots/dbt_lineage.png" width="850">
</p>

---

# Analytics Dashboards (Metabase)

Dashboards provide:

- Trip volume and revenue  
- Vendor performance trends  
- Payment type distribution and tip rates  
- Pickup-zone spatial analytics  

<p align="center">
  <img src="screenshots/metabase_dashboard.png" width="850">
</p>

---

# Batch Semantics & Determinism

- Data processed in **monthly batches (YYYY-MM)**  
- Spark ingestion → warehouse persistence → dbt transformation  

### Safe Reruns

- Full snapshot replacement  
- Partial failures do not corrupt historical data  

### Late / Early Trip Handling

| Category | Handling |
|----------|----------|
| Clean | Base table |
| Suspicious | Base + Quarantine |
| Critical | Quarantine only |

---

# Design Principles

| Principle | Implementation |
|-----------|----------------|
| Correctness over throughput | Batch processing (~15 min per batch) |
| Deterministic ELT snapshots | Partition + truncate + rewrite |
| Explicit DQ signaling | DQ flags instead of filtering |
| Separation of layers | Spark ingestion vs dbt analytics |

---

# Lessons Learned

- Late-arriving data requires explicit classification  
- Partitioning improves rerun efficiency and storage management  
- Operational metadata is critical for debugging  
- Clear separation of ingestion and transformation improves maintainability  

---

# Summary

- Enterprise-grade **safe, re-runnable batch ELT pipeline**  
- Treats **data quality as analytical output**  
- Fully **containerized stack**: Airflow, Spark, dbt, PostgreSQL, Metabase  
- Optimized for reproducibility, modularity, and performance
