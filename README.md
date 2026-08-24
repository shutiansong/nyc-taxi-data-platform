# NYC Taxi Batch ELT Platform V2

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Repo Size](https://img.shields.io/github/repo-size/shutiansong/nyc-taxi-data-platform)](https://github.com/shutiansong/nyc-taxi-data-platform)
[![Last Commit](https://img.shields.io/github/last-commit/shutiansong/nyc-taxi-data-platform)](https://github.com/shutiansong/nyc-taxi-data-platform)

[![Docker](https://img.shields.io/badge/Docker-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![Airflow](https://img.shields.io/badge/Airflow-017CEE?logo=apacheairflow&logoColor=white)](https://airflow.apache.org/)
[![Spark](https://img.shields.io/badge/Spark-E25A1C?logo=apachespark&logoColor=white)](https://spark.apache.org/)
[![MinIO](https://img.shields.io/badge/MinIO-C72E29?logo=minio&logoColor=white)](https://min.io/)
[![Postgres](https://img.shields.io/badge/Postgres-336791?logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![StarRocks](https://img.shields.io/badge/StarRocks-OLAP-blue)](https://www.starrocks.io/)
[![dbt](https://img.shields.io/badge/dbt-FF694B?logo=dbt&logoColor=white)](https://www.getdbt.com/)
[![Metabase](https://img.shields.io/badge/Metabase-509EE3?logo=metabase&logoColor=white)](https://www.metabase.com/)

![Pipeline](https://img.shields.io/badge/Pipeline-Batch-blue)
![ELT](https://img.shields.io/badge/ELT-Idempotent-orange)
![Data Quality](https://img.shields.io/badge/Data%20Quality-Validated-green)
![Storage](https://img.shields.io/badge/Storage-Parquet-purple)
![Warehouse](https://img.shields.io/badge/Warehouse-StarRocks-blue)
![Infrastructure](https://img.shields.io/badge/Infra-Dockerized-2496ED)
![Processing Model](https://img.shields.io/badge/Processing-Deterministic-red)

A production-style **batch ELT data platform built around the NYC Taxi trip dataset**, evolved from a PostgreSQL-based V1 architecture into a storage-separated V2 architecture using object storage and an OLAP warehouse.

The platform focuses on **deterministic batch processing, data quality handling, idempotent reruns, operational metadata, and analytical scalability**.

The project is fully containerized with **Docker Compose**. The public repository focuses on architecture, documentation, configuration references, and workflow screenshots rather than exposing the complete implementation code.

---

# Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [V1 → V2 Evolution](#v1--v2-evolution)
3. [Technology Stack](#technology-stack)
4. [Repository Structure](#repository-structure)
5. [Batch Processing](#batch-processing)
6. [Data Quality](#data-quality)
7. [Analytical Modeling](#analytical-modeling)
8. [Operational Metadata](#operational-metadata)
9. [Performance](#performance)
10. [Lessons Learned](#lessons-learned)
11. [Summary](#summary)

---

# Architecture Overview

<p align="center">
  <img src="screenshots/v2_pipeline_architecture.png" width="900">
</p>

The V2 pipeline follows a storage-separated batch ELT architecture:

```text
    NYC Taxi Monthly Parquet
              │
              ▼
            MinIO
             Raw
              │
              ▼
        Spark Batch ELT
              │
         ┌────┴─────────────┐
         │                  │
         ▼                  ▼
       MinIO             Postgres
   Base/Quarantine      Metadata
         │
         ▼
   StarRocks External Tables
         │
         ▼
        dbt
         │
         ▼
   Analytics Models
         │
         ▼
      Metabase
```

The processing flow is:

**Parquet → MinIO Raw → Spark → MinIO Base/Quarantine + Postgres Metadata → StarRocks External Tables → dbt → Analytics → Metabase**

MinIO provides the durable Parquet storage layer, while StarRocks serves the analytical workload. Postgres is used separately for operational metadata.

---

# V1 → V2 Evolution

The project started with a PostgreSQL-centered V1 architecture:

```text
    Monthly Parquet
          │
          ▼
       Spark ELT
          │
          ▼
       Postgres
          │
          ▼
          dbt
          │
          ▼
      Analytics
          │
          ▼
       Metabase
```

V1 provided a simple and reliable batch ELT workflow, but PostgreSQL was responsible for both persistent data storage and analytical workloads.

Before moving to V2, the V1 pipeline was optimized around rerun behavior, PostgreSQL table bloat, dbt test performance, and temporary storage pressure.

V2 separates durable storage from analytical serving:

```text
    Raw Parquet
         │
         ▼
        MinIO
         │
     ┌───┴────────────┐
     ▼                ▼
    Base         Quarantine
     │                │
     └───────┬────────┘
             ▼
   StarRocks External Tables
             │
             ▼
            dbt
             │
             ▼
        Analytics
```

The V2 redesign reduced end-to-end pipeline runtime from approximately **15 minutes in V1 to approximately 3 minutes in V2**, while retaining the existing batch semantics, data quality handling, and analytical models.

The original V1 documentation is preserved under `docs/v1/README.md`.

---

# Technology Stack

| Layer | Technology |
|------|------------|
| Orchestration | Apache Airflow |
| Processing | Apache Spark / PySpark |
| Object Storage | MinIO |
| Metadata Store | Postgres |
| Analytical Warehouse | StarRocks |
| Transformation | dbt |
| BI / Visualization | Metabase |
| Infrastructure | Docker Compose |
| Data Format | Parquet |
| Data Source | NYC Yellow Taxi Trip Data |

---

# Repository Structure

The V2 project is organized as a set of independently containerized services.

    project-root/
    │
    ├── airflow/
    │   ├── Dockerfile
    │   ├── docker-compose.yaml
    │   ├── config/
    │   ├── dags/
    │   ├── logs/
    │   ├── plugins/
    │   ├── requirements.txt
    │   └── sql/
    │
    ├── spark/
    │   ├── Dockerfile
    │   ├── docker-compose.yaml
    │   ├── conf/
    │   ├── jobs/
    │   └── requirements.txt
    │
    ├── minio/
    │   ├── docker-compose.yaml
    │   └── data/
    │
    ├── postgres/
    │   ├── docker-compose.yaml
    │   └── ddl/
    │
    ├── starrocks/
    │   ├── docker-compose.yaml
    │   ├── ddl/
    │   └── data/
    │
    ├── dbt/
    │   ├── Dockerfile
    │   ├── docker-compose.yaml
    │   ├── profiles.yml
    │   ├── logs/
    │   ├── ny_taxi_rides/
    │   └── ny_taxi_rides_v2/
    │
    └── metabase/
        ├── docker-compose.yaml
        ├── plugins/
        └── pg_data/

Airflow, Spark, and dbt each have their own Dockerfile and Docker Compose configuration. The remaining services are defined through their respective Docker Compose configurations.

The public GitHub repository focuses on **architecture, documentation, configuration references, and workflow screenshots** rather than exposing the complete implementation code.

The original V1 documentation is retained separately under `docs/v1/README.md`.

---

# Batch Processing

The pipeline processes NYC Taxi data as deterministic monthly batches.

    batch_id = YYYY-MM

For example:

    2024-01
    2024-02
    2024-03
    ...
    2024-12

The same `batch_id` represents the same logical processing unit throughout the pipeline.

This provides a consistent basis for:

- idempotent reruns
- historical backfills
- partition-level replacement
- batch-level validation
- operational metadata tracking

Raw monthly Parquet files are first written to MinIO:

    s3a://<bucket>/raw/<batch_id>/

Spark then reads the corresponding raw batch and writes processed data back to MinIO:

    s3a://<bucket>/base/<batch_id>/
    s3a://<bucket>/quarantine/<batch_id>/

The processed Base and Quarantine datasets are exposed to StarRocks through external tables.

---

# Data Quality

Spark performs data cleansing and quality validation during batch processing.

Each record is classified into one of three quality states:

    clean
    suspicious
    critical

The routing strategy is:

| Quality Status | Destination |
|----------------|-------------|
| Clean | Base |
| Suspicious | Base + Quarantine |
| Critical | Quarantine |

Instead of silently filtering anomalous records, the pipeline preserves them in the appropriate storage layer and carries the data quality signal downstream.

This makes data quality issues available for investigation and keeps the processing result traceable and auditable.

<p align="center">
  <img src="screenshots/airflow_dag.png" width="900">
</p>

---

# Analytical Modeling

StarRocks exposes the processed Parquet datasets stored in MinIO through external tables.

dbt performs the downstream transformations directly in StarRocks:

    Processed Data
          │
          ▼
       Staging
          │
          ▼
     Intermediate
          │
          ▼
      Analytics

The dbt project separates source preparation, business transformations, and analytical models.

The final analytical layer contains models such as:

    dim_vendor
    dim_rate_code
    dim_payment_type
    dim_zones

    fct_trips_wide
    fct_trips_daily_vendor
    fct_trips_daily_pickup_zone
    fct_trips_daily_payment_type

These models support analytical use cases including trip volume, revenue, vendor performance, payment behavior, and pickup-zone analysis.

<p align="center">
  <img src="screenshots/dbt_lineage.png" width="900">
</p>

Metabase consumes the final analytical models for BI and visualization.

<p align="center">
  <img src="screenshots/metabase_dashboard.png" width="900">
</p>

---

# Operational Metadata

Operational metadata is stored separately in Postgres rather than in the analytical storage layer.

The main metadata table is:

    metadata.batch_ingestion_stats

It records batch-level information including:

- input row count
- processed output counts
- Base and Quarantine distributions
- data quality statistics
- minimum pickup timestamp
- maximum pickup timestamp

The metadata supports batch validation, troubleshooting, auditing, and operational monitoring.

Airflow failure callbacks and SLA configuration provide additional task-level failure tracking.

---

# Performance

The V2 architecture significantly reduced the end-to-end pipeline runtime:

| Version | Architecture | Runtime |
|---------|--------------|---------|
| V1 | Spark → Postgres → dbt → Metabase | ~15 min |
| V2 | MinIO → Spark → MinIO → StarRocks → dbt → Metabase | ~3 min |

The V1 implementation was also optimized before the V2 migration.

Key V1 improvements included:

- partition-level `TRUNCATE + REWRITE` for rerun-safe loading
- partition-aware dbt tests
- reduced unnecessary full-table scans
- reduced PostgreSQL temporary storage pressure

These changes reduced dbt test time from approximately **15 minutes to 8–9 minutes** and reduced PostgreSQL temporary file usage from approximately **100 GB to less than 50 MB**.

The V2 redesign then addressed the larger architectural limitation by separating durable storage from analytical serving.

---

# Lessons Learned

## 1. Separate durable storage from analytical serving

Object storage is better suited for retaining processed datasets, while an OLAP warehouse can focus on analytical workloads.

This separation reduces coupling between persistent storage and analytical processing.

## 2. Design rerun semantics explicitly

A batch pipeline should define what happens when the same batch is executed again.

Deterministic batch identifiers and partition-level replacement make reruns predictable and prevent duplicate accumulation.

## 3. Preserve data quality signals

Data quality issues should not automatically disappear during ingestion.

Routing anomalous records to quarantine while retaining their quality status makes downstream investigation and auditing possible.

## 4. Optimize before redesigning

The V1 implementation was first optimized around its actual bottlenecks.

The V2 redesign was then introduced to address the architectural limitations that remained after those optimizations.

---

# Summary

NYC Taxi Batch ELT Platform V2 demonstrates a production-style batch data engineering architecture built around:

- **Airflow** for orchestration
- **Spark** for batch processing and data quality
- **MinIO** for Parquet-based object storage
- **Postgres** for operational metadata
- **StarRocks** for analytical serving
- **dbt** for data modeling
- **Metabase** for BI
- **Docker Compose** for containerized deployment

The project evolved from a PostgreSQL-centered V1 pipeline into a storage-separated V2 architecture while preserving deterministic batch processing, data quality handling, and analytical models.

The V2 redesign reduced end-to-end pipeline runtime from approximately **15 minutes to 3 minutes**.
