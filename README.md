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

A production-style **batch ELT data platform built around the NYC Taxi trip dataset**, evolved from a Postgres-based V1 implementation into an object-storage and OLAP-based V2 architecture.

The platform focuses on **deterministic batch processing, explicit data quality signaling, safe reruns, operational metadata, and analytical scalability**.

All components are containerized and orchestrated through **Docker Compose** for reproducible local deployment.

---

# Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [V1 → V2 Architecture Evolution](#v1--v2-architecture-evolution)
3. [Technology Stack](#technology-stack)
4. [Repository Structure](#repository-structure)
5. [Batch Semantics & Determinism](#batch-semantics--determinism)
6. [Spark ELT & Data Quality](#spark-elt--data-quality)
7. [Data Storage Architecture](#data-storage-architecture)
8. [dbt Transformation Layer](#dbt-transformation-layer)
9. [Pipeline Orchestration](#pipeline-orchestration)
10. [Operational Metadata & Observability](#operational-metadata--observability)
11. [Analytics Dashboards](#analytics-dashboards)
12. [Performance Improvement](#performance-improvement)
13. [Design Principles](#design-principles)
14. [Lessons Learned](#lessons-learned)
15. [Summary](#summary)

---

# Architecture Overview

<p align="center">
  <img src="screenshots/v2_pipeline_architecture.png" width="900">
</p>

### V2 Data Flow

    NYC Taxi Monthly Parquet
              │
              ▼
            MinIO
             Raw
              │
              ▼
        Spark Batch ELT
              │
        ┌─────┴───────────┐
        │                 │
        ▼                 ▼
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

The V2 architecture separates **durable storage, batch processing, analytical serving, and operational metadata**.

Raw Parquet data is first stored in MinIO. Spark reads the raw data, performs batch ELT and data quality processing, and writes the resulting Base and Quarantine datasets back to MinIO while recording batch-level metadata in Postgres.

StarRocks exposes the processed Parquet datasets through external tables. dbt then performs the analytical transformations directly in StarRocks, with Metabase consuming the resulting analytical models.

---

# V1 → V2 Architecture Evolution

The project originally used Postgres as both the raw data store and analytical warehouse.

### V1

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

V1 provided a deterministic and rerun-safe batch ELT workflow, but Postgres handled both large-scale data storage and analytical workloads.

Before the V2 migration, the V1 pipeline was optimized to improve rerun behavior and dbt test performance. This included partition-level truncate-and-rewrite for batch replacement and partition-aware dbt tests.

### V2

    Monthly Parquet
          │
          ▼
         MinIO
          │
          ▼
       Spark ELT
          │
      ┌───┴────────────┐
      ▼                ▼
    Base          Quarantine
      │
      ▼
   StarRocks
 External Tables
      │
      ▼
     dbt
      │
      ▼
  Analytics
      │
      ▼
  Metabase

The V2 redesign separates durable Parquet storage from analytical serving:

- MinIO provides the durable object storage layer.
- StarRocks provides the analytical warehouse layer.
- Postgres is retained for operational metadata.
- The existing batch semantics, data quality handling, and analytical models are preserved.

---

# Technology Stack

| Layer | Technology |
|------|------------|
| Orchestration | Apache Airflow |
| Processing | Apache Spark / PySpark |
| Object Storage | MinIO |
| Analytical Warehouse | StarRocks |
| Transformation | dbt |
| Operational Metadata | Postgres |
| BI / Visualization | Metabase |
| Infrastructure | Docker Compose |
| Data Format | Parquet |
| Data Source | NYC Yellow Taxi Trip Data |

---

# Repository Structure

The public repository focuses on **architecture, documentation, configuration references, and workflow screenshots** rather than exposing the complete implementation code.

The local V2 project is organized as a set of independent containerized services:

    project-root/
    │
    ├── airflow/
    │   ├── Dockerfile
    │   ├── config/
    │   ├── dags/
    │   ├── docker-compose.yaml
    │   ├── logs/
    │   ├── plugins/
    │   ├── requirements.txt
    │   └── sql/
    │
    ├── spark/
    │   ├── Dockerfile
    │   ├── conf/
    │   ├── docker-compose.yaml
    │   ├── jobs/
    │   └── requirements.txt
    │
    ├── minio/
    │   ├── data/
    │   └── docker-compose.yaml
    │
    ├── postgres/
    │   ├── ddl/
    │   └── docker-compose.yaml
    │
    ├── starrocks/
    │   ├── data/
    │   ├── ddl/
    │   └── docker-compose.yaml
    │
    ├── dbt/
    │   ├── Dockerfile
    │   ├── docker-compose.yaml
    │   ├── logs/
    │   ├── ny_taxi_rides/
    │   ├── ny_taxi_rides_v2/
    │   └── profiles.yml
    │
    └── metabase/
        ├── docker-compose.yaml
        ├── pg_data/
        └── plugins/

The V1 dbt project is retained alongside the V2 project to preserve the evolution of the analytical layer.

The GitHub repository documents the architecture and development process without exposing the complete local implementation.

---

# Batch Semantics & Determinism

The pipeline processes NYC Taxi data in deterministic monthly batches.

    batch_id = YYYY-MM

For example:

    2024-01
    2024-02
    2024-03
    ...
    2024-12

Each `batch_id` represents an independent processing unit.

The batch design supports:

- deterministic monthly processing
- idempotent reruns
- historical backfills
- partition-level replacement
- recovery from partial failures

Rerunning the same batch replaces the corresponding batch data instead of appending another copy of the same records.

---

# Spark ELT & Data Quality

Spark performs the batch ELT processing between the Raw, Base, and Quarantine layers.

Each source record is classified into one of three quality states:

| Quality Status | Destination |
|----------------|-------------|
| Clean | Base |
| Suspicious | Base + Quarantine |
| Critical | Quarantine |

This allows anomalous records to be retained instead of silently discarded.

The resulting data quality status is propagated downstream so that data issues remain traceable during analytical processing.

---

# Data Storage Architecture

## MinIO

MinIO stores the raw and processed Parquet datasets.

The storage layout is organized by processing layer and batch:

    s3a://<bucket>/
    │
    ├── raw/
    │   └── <batch_id>/
    │
    ├── base/
    │   └── <batch_id>/
    │
    └── quarantine/
        └── <batch_id>/

### Raw

The Raw layer contains the source Parquet data before Spark processing.

### Base

The Base layer contains records available for downstream analytical processing.

### Quarantine

The Quarantine layer retains records that require investigation or should not enter the analytical dataset directly.

## StarRocks

StarRocks exposes the processed Base datasets through external tables and serves as the analytical warehouse for dbt models.

The analytical layer contains models such as:

    dim_vendor
    dim_rate_code
    dim_payment_type
    dim_zones

    fct_trips_wide
    fct_trips_daily_vendor
    fct_trips_daily_pickup_zone
    fct_trips_daily_payment_type

---

# dbt Transformation Layer

dbt performs the analytical transformation directly in StarRocks.

    Staging
       │
       ▼
    Intermediate
       │
       ▼
    Analytics

### Staging

Provides a stable interface over the processed source data and standardizes fields for downstream transformations.

### Intermediate

Handles business-level transformations including deduplication, metric derivation, and field transformations.

### Analytics

Produces analytical fact tables and daily aggregate models used by the BI layer.

Examples include:

- trip-level fact tables
- daily vendor aggregates
- daily payment-type aggregates
- daily pickup-zone aggregates

<p align="center">
  <img src="screenshots/dbt_lineage.png" width="900">
</p>

The V2 dbt project retains the analytical modeling approach established in V1 while changing the underlying analytical storage layer to StarRocks.

---

# Pipeline Orchestration

Airflow coordinates the monthly batch workflow and manages task dependencies and execution.

Key responsibilities include:

- monthly batch scheduling
- dependency management
- Spark job execution
- dbt execution
- failure handling
- SLA monitoring
- operational metadata collection

Example DAG:

<p align="center">
  <img src="screenshots/airflow_dag.png" width="900">
</p>

The deterministic `batch_id` allows individual monthly batches to be rerun or backfilled without rebuilding the entire dataset.

---

# Operational Metadata & Observability

Operational metadata is stored separately from the analytical data.

The main metadata table is:

    metadata.batch_ingestion_stats

It records batch-level information including:

- input row count
- Base output row count
- Quarantine row count
- data quality distribution
- minimum pickup timestamp
- maximum pickup timestamp

This metadata supports batch validation, anomaly investigation, pipeline auditing, and debugging.

Airflow failure callbacks and SLA configuration provide additional task-level failure tracking.

---

# Analytics Dashboards

Metabase provides the BI layer on top of the StarRocks analytical models.

The dashboards cover use cases including:

- trip volume
- revenue and fare metrics
- vendor performance
- payment type distribution
- tip analysis
- pickup-zone analytics

<p align="center">
  <img src="screenshots/metabase_dashboard.png" width="900">
</p>

The analytical models and dashboard structure are largely retained from V1, allowing the BI layer to remain stable during the storage architecture migration.

---

# Performance Improvement

The V2 architecture reduced end-to-end pipeline runtime:

| Version | Architecture | End-to-End Runtime |
|---------|--------------|--------------------|
| V1 | Spark → Postgres → dbt → Metabase | ~15 min |
| V2 | MinIO → Spark → StarRocks → dbt → Metabase | ~3 min |

The V1 Postgres implementation was optimized before the migration through:

- partition-level truncate and rewrite for rerun-safe loading
- partition-aware dbt tests
- reduced unnecessary full-table scans
- reduced Postgres temporary storage pressure

These optimizations reduced dbt test time from approximately **15 minutes to 8–9 minutes** and reduced Postgres temporary storage usage from approximately **100 GB to less than 50 MB**.

The V2 migration then separated durable storage from analytical serving, resulting in the approximately **15-minute to 3-minute** end-to-end runtime improvement.

---

# Design Principles

| Principle | Implementation |
|-----------|----------------|
| Deterministic processing | Monthly `batch_id = YYYY-MM` |
| Safe reruns | Partition-level replacement |
| Explicit data quality | Quality classification and quarantine |
| Durable storage | Parquet datasets in MinIO |
| Analytical serving | StarRocks OLAP warehouse |
| Transformation separation | Spark ingestion + dbt modeling |
| Operational visibility | Batch metadata + Airflow monitoring |
| Reproducibility | Docker Compose |

---

# Lessons Learned

## 1. Separate durable storage from analytical serving

Durable datasets and analytical workloads have different requirements.

Object storage provides a flexible foundation for retaining processed datasets, while the OLAP warehouse can focus on analytical serving.

## 2. Make data quality observable

Data quality issues are easier to investigate when anomalous records are classified and retained instead of being silently discarded.

## 3. Define rerun semantics explicitly

A batch pipeline should define what happens when the same batch is processed again.

Deterministic batch identifiers and partition-level replacement make reruns predictable and prevent duplicate accumulation.

## 4. Optimize before redesigning

The V1 implementation was first optimized around its actual bottlenecks, including rerun behavior, dbt test performance, and Postgres temporary storage.

The V2 redesign then separated durable storage from analytical serving to provide a more scalable architecture.

---

# Summary

NYC Taxi Batch ELT Platform V2 demonstrates an end-to-end batch data engineering architecture using:

- **Airflow** for orchestration
- **Spark** for batch ELT and data quality processing
- **MinIO** for durable Parquet storage
- **Postgres** for operational metadata
- **StarRocks** for analytical workloads
- **dbt** for analytical transformation and modeling
- **Metabase** for BI and visualization
- **Docker Compose** for reproducible deployment

The project evolved from a Postgres-based V1 implementation into a storage-separated V2 architecture while preserving deterministic batch processing, data quality handling, analytical models, and operational metadata.

The V2 redesign reduced end-to-end pipeline runtime from approximately **15 minutes to 3 minutes**.
