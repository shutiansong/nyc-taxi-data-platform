#!/usr/bin/env bash

set -e

docker compose -f airflow/docker-compose.yaml up -d
docker compose -f spark/docker-compose.yaml up -d
docker compose -f minio/docker-compose.yaml up -d
docker compose -f postgres/docker-compose.yaml up -d
docker compose -f starrocks/docker-compose.yaml up -d
docker compose -f dbt/docker-compose.yaml up -d
docker compose -f metabase/docker-compose.yaml up -d

echo "NYC Taxi Data Platform started."