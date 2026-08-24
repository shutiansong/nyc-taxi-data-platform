# NYC Taxi Batch ELT Platform V2

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Repo Size](https://img.shields.io/github/repo-size/shutiansong/nyc-taxi-data-platform)](https://github.com/shutiansong/nyc-taxi-data-platform)
[![Last Commit](https://img.shields.io/github/last-commit/shutiansong/nyc-taxi-data-platform)](https://github.com/shutiansong/nyc-taxi-data-platform)

[![Docker](https://img.shields.io/badge/Docker-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![Airflow](https://img.shields.io/badge/Airflow-017CEE?logo=apacheairflow&logoColor=white)](https://airflow.apache.org/)
[![Spark](https://img.shields.io/badge/Spark-E25A1C?logo=apachespark&logoColor=white)](https://spark.apache.org/)
[![MinIO](https://img.shields.io/badge/MinIO-C72E29?logo=minio&logoColor=white)](https://min.io/)
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

A production-style **batch ELT data platform built around the NYC Taxi trip dataset**, redesigned from a PostgreSQL-based V1 architecture into an object-storage and OLAP-based V2 architecture.

The platform emphasizes **deterministic batch processing, explicit data quality signaling, safe reruns, operational metadata, and analytical scalability**.

All components are containerized and orchestrated through **Docker Compose** for reproducible local deployment.

---

# Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [V1 → V2 Architecture Evolution](#v1--v2-architecture-evolution)
3. [Technology Stack](#technology-stack)
4. [Repository Structure](#repository-structure)
5. [Batch Semantics & Determinism](#batch-semantics--determinism)
6. [Pipeline Orchestration](#pipeline-orchestration)
7. [Spark ELT & Data Quality](#spark-elt--data-quality)
8. [Data Storage Architecture](#data-storage-architecture)
9. [dbt Transformation Layer](#dbt-transformation-layer)
10. [Operational Metadata & Observability](#operational-metadata--observability)
11. [Analytics Dashboards](#analytics-dashboards)
12. [Performance Improvement](#performance-improvement)
13. [Design Principles](#design-principles)
14. [Lessons Learned](#lessons-learned)

---

# Architecture Overview

<p align="center">
  <img src="screenshots/v2_pipeline_architecture.png" width="900">
</p>

### V2 Pipeline Flow

```text
NYC Taxi Monthly Parquet
          │
          ▼
      Airflow
          │
          ▼
    Spark Batch ELT
          │
          ▼
    ┌───────────────┐
    │   MinIO       │
    │ Object Store  │
    └───────────────┘
          │
          ├── Raw
          │
          ├── Base
          │
          └── Quarantine
                  │
                  ▼
              dbt
                  │
                  ▼
          ┌───────────────┐
          │   StarRocks   │
          │  OLAP Layer   │
          └───────────────┘
                  │
                  ▼
              Metabase

The V2 architecture separates **object storage, data processing, analytical storage, and BI**:

* **Airflow** orchestrates monthly batch processing
* **Spark** performs ingestion, cleansing, and data quality classification
* **MinIO** provides durable Parquet-based object storage
* **dbt** manages analytical transformations and data modeling
* **StarRocks** serves as the analytical OLAP warehouse
* **Postgres** stores operational metadata
* **Metabase** provides analytical dashboards

---

# V1 → V2 Architecture Evolution

The project originally used PostgreSQL as both the raw data store and analytical warehouse.

### V1

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

The V1 architecture provided a simple and reliable batch ELT workflow, but the PostgreSQL warehouse became the main storage and processing bottleneck as the dataset grew.

### V2

```text
Monthly Parquet
      │
      ▼
   Spark ELT
      │
      ▼
     MinIO
      │
      ├── Raw
      ├── Base
      └── Quarantine
             │
             ▼
            dbt
             │
             ▼
         StarRocks
             │
             ▼
          Metabase
```

V2 separates durable data storage from analytical serving:

* MinIO stores Parquet datasets
* Spark handles ingestion and data quality processing
* StarRocks provides the analytical warehouse layer
* dbt remains responsible for business transformations
* Postgres continues to store operational metadata

This redesign reduced the end-to-end pipeline runtime from approximately **15 minutes in V1 to approximately 3 minutes in V2** while retaining the existing batch semantics, data quality handling, and analytical models.

---

# Technology Stack

| Layer                | Technology                |
| -------------------- | ------------------------- |
| Orchestration        | Apache Airflow            |
| Processing           | Apache Spark / PySpark    |
| Object Storage       | MinIO                     |
| Analytical Warehouse | StarRocks                 |
| Transformation       | dbt                       |
| Metadata Store       | PostgreSQL                |
| BI / Visualization   | Metabase                  |
| Infrastructure       | Docker Compose            |
| Data Format          | Parquet                   |
| Data Source          | NYC Yellow Taxi Trip Data |

---

# Repository Structure

The public repository focuses on **architecture, configuration, documentation, and workflow screenshots** rather than exposing the complete implementation code.

```text
nyc-taxi-data-platform
│
├── screenshots/
│   ├── v1_pipeline_architecture.png
│   ├── v2_pipeline_architecture.png
│   ├── airflow_dag.png
│   ├── dbt_lineage.png
│   └── metabase_dashboard.png
│
├── docs/
│   └── v1/
│       └── README.md
│
└── README.md
```

The `docs/v1/README.md` contains the original V1 architecture and implementation documentation.

---

# Batch Semantics & Determinism

The pipeline processes NYC Taxi data in deterministic monthly batches.

```text
batch_id = YYYY-MM
```

For example:

```text
2024-01
2024-02
2024-03
...
2024-12
```

Each batch represents a deterministic processing unit.

### Safe Reruns

The pipeline is designed so that rerunning the same batch does not append duplicate records.

The batch processing strategy supports:

* deterministic monthly processing
* idempotent reruns
* historical backfills
* partition-level replacement
* partial failure recovery

### Data Quality Routing

| Data Quality | Storage           |
| ------------ | ----------------- |
| Clean        | Base              |
| Suspicious   | Base + Quarantine |
| Critical     | Quarantine        |

This allows anomalous records to remain available for investigation instead of being silently discarded.

---

# Pipeline Orchestration

Airflow orchestrates the complete batch pipeline.

Key responsibilities include:

* monthly batch scheduling
* dependency management
* Spark job execution
* downstream dbt execution
* data quality validation
* operational metadata collection
* failure handling
* SLA monitoring

Example DAG:

<p align="center">
  <img src="screenshots/airflow_dag.png" width="900">
</p>

The pipeline is designed around a deterministic `batch_id`, allowing individual monthly batches to be rerun or backfilled without rebuilding the entire dataset.

---

# Spark ELT & Data Quality

Spark performs the initial batch ELT processing.

### Processing Responsibilities

* read monthly NYC Taxi Parquet data
* standardize and clean source fields
* validate timestamps and numeric fields
* identify suspicious and critical records
* assign data quality status
* write processed datasets to MinIO

### Data Quality Classification

Each source record is classified into one of three categories:

```text
clean
suspicious
critical
```

The classification determines where the record is written.

```text
Clean
  └── Base

Suspicious
  ├── Base
  └── Quarantine

Critical
  └── Quarantine
```

Rather than simply filtering invalid records, the pipeline preserves anomalous data and propagates the associated data quality signal downstream.

This makes data quality issues **traceable and auditable**.

---

# Data Storage Architecture

V2 uses MinIO as the durable object storage layer and StarRocks as the analytical warehouse.

### MinIO

Processed Parquet datasets are organized by processing layer and batch:

```text
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
```

This separation keeps raw source data independent from processed datasets.

### Raw

Raw Parquet files represent the source data before data quality routing.

### Base

Base contains records that pass the required processing rules.

Suspicious records may also be retained in Base while carrying a data quality signal.

### Quarantine

Quarantine contains records that require additional investigation or should not enter the analytical dataset.

### StarRocks

StarRocks serves as the OLAP warehouse for analytical workloads.

The analytical layer contains dbt-generated models such as:

```text
dim_vendor
dim_rate_code
dim_payment_type
dim_zones

fct_trips_wide
fct_trips_daily_vendor
fct_trips_daily_pickup_zone
fct_trips_daily_payment_type
```

---

# dbt Transformation Layer

dbt manages the analytical transformation layer.

```text
Staging
   │
   ▼
Intermediate
   │
   ▼
Analytics
```

### Staging

The staging layer provides a stable interface over processed source data and standardizes fields for downstream transformations.

### Intermediate

The intermediate layer performs:

* business-level deduplication
* metric derivation
* field transformations
* data quality signal propagation

### Analytics

The analytics layer produces analytical fact and aggregate models.

Examples include:

* trip-level fact tables
* daily vendor aggregates
* daily payment-type aggregates
* daily pickup-zone aggregates

Example dbt lineage:

<p align="center">
  <img src="screenshots/dbt_lineage.png" width="900">
</p>

---

# Operational Metadata & Observability

Operational metadata is maintained separately from the analytical data stored in MinIO and StarRocks.

The metadata table:

```text
metadata.batch_ingestion_stats
```

records batch-level information including:

* input row count
* base output row count
* quarantine row count
* data quality distribution
* minimum pickup timestamp
* maximum pickup timestamp

This metadata is used for:

* batch validation
* anomaly investigation
* pipeline auditing
* debugging
* operational monitoring

Airflow failure callbacks and SLA configuration provide additional task-level failure tracking.

---

# Analytics Dashboards

Metabase provides the BI layer on top of StarRocks.

The dashboards cover analytical use cases including:

* trip volume
* revenue and fare metrics
* vendor performance
* payment type distribution
* tip analysis
* pickup-zone analytics

<p align="center">
  <img src="screenshots/metabase_dashboard.png" width="900">
</p>

The same analytical models are reused across V1 and V2, allowing the BI layer to remain largely unchanged during the storage architecture migration.

---

# Performance Improvement

The V2 architecture significantly reduced end-to-end pipeline runtime.

| Version | Architecture                               | End-to-End Runtime |
| ------- | ------------------------------------------ | ------------------ |
| V1      | Spark → Postgres → dbt → Metabase          | ~15 min            |
| V2      | Spark → MinIO → dbt → StarRocks → Metabase | ~3 min             |

```text
V1   ███████████████  ~15 min

V2   ███              ~3 min
```

The V1 PostgreSQL implementation was also optimized before the V2 migration.

Key improvements included:

* partition-level truncate and rewrite for safe reruns
* partition-aware dbt tests
* reduced unnecessary full-table scans
* reduced PostgreSQL temporary storage pressure

The original dbt test workload was reduced from approximately **15 minutes to 8–9 minutes**, while PostgreSQL temporary storage usage during large-scale tests decreased from approximately **100 GB to less than 50 MB**.

---

# Design Principles

| Principle                 | Implementation                      |
| ------------------------- | ----------------------------------- |
| Deterministic processing  | Monthly `batch_id = YYYY-MM`        |
| Safe reruns               | Partition-level replacement         |
| Explicit data quality     | Clean / Suspicious / Critical       |
| Durable storage           | Parquet datasets in MinIO           |
| Analytical performance    | StarRocks OLAP warehouse            |
| Transformation separation | Spark ingestion + dbt modeling      |
| Operational visibility    | Batch metadata + Airflow monitoring |
| Reproducibility           | Docker Compose                      |

---

# Lessons Learned

### 1. Separate storage from analytical serving

Using an OLAP warehouse directly as the only storage layer creates unnecessary coupling between durable data storage and analytical workloads.

Object storage provides a more flexible foundation for retaining processed datasets, while StarRocks can focus on analytical serving.

### 2. Data quality should be observable

Invalid or suspicious records should not always be silently removed.

Explicit classification and quarantine make data quality issues easier to investigate and audit.

### 3. Rerun semantics should be designed first

A batch pipeline should define what happens when the same batch runs twice.

Deterministic batch identifiers and partition-level replacement make reruns predictable.

### 4. Performance optimization should follow actual bottlenecks

The V1 PostgreSQL implementation was optimized first to address rerun behavior, testing overhead, and temporary storage pressure.

The V2 redesign then moved durable storage and analytical serving into separate layers.

---

# Summary

NYC Taxi Batch ELT Platform V2 demonstrates an end-to-end data engineering workflow covering:

* **Airflow** for orchestration
* **Spark** for batch ELT and data quality processing
* **MinIO** for Parquet-based object storage
* **dbt** for analytical transformation
* **StarRocks** for OLAP workloads
* **Postgres** for operational metadata
* **Metabase** for BI and visualization
* **Docker Compose** for containerized deployment

The project evolved from a PostgreSQL-based V1 implementation into a storage-separated V2 architecture while preserving deterministic batch processing, data quality handling, analytical models, and operational metadata.

The V2 redesign reduced end-to-end pipeline runtime from approximately **15 minutes to 3 minutes**.

```
```

