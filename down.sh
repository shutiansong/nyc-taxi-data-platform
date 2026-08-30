#!/usr/bin/env bash

set -e

docker compose -f airflow/docker-compose.yaml down
docker compose -f spark/docker-compose.yaml down
docker compose -f minio/docker-compose.yaml down
docker compose -f postgres/docker-compose.yaml down
docker compose -f starrocks/docker-compose.yaml down
docker compose -f dbt/docker-compose.yaml down
docker compose -f metabase/docker-compose.yaml down

echo "NYC Taxi Data Platform stopped."