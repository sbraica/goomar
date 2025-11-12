#!/bin/bash
git pull
echo "BUILD FLUTTER"
cd ../gui
flutter build web --release
rm build/web/index.html
cp -r build/web/*  ../API/src/main/resources/static/login/
echo "BUILD API"
cd ../API
mvn clean install
docker build -t goomar .
docker image prune -f
docker compose up -d --force-recreate goomar