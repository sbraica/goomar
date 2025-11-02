#!/bin/bash
git pull
echo "BUILD API"
cd ../API
mvn clean install
docker build -t goomar_api .
docker image prune -f
cd ../gui
docker-compose down
docker-compose up -d
