#!/bin/bash
set -e

docker-compose stop
docker-compose rm -f
docker-compose build
docker-compose up -d --remove-orphans
docker-compose logs -f agent
