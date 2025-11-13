#!/bin/bash
git pull
echo "BUILD API"
cd ../API
mvn clean install
docker build -t goomar .
docker image prune -f
docker compose up -d --force-recreate goomar