#!/bin/bash
git pull
echo "BUILD GUI"
sed -i "s/^GIT_COMMIT=.*/GIT_COMMIT=$(git rev-parse --short HEAD)/" assets/.env
dart run build_runner build --delete-conflicting-outputs
flutter build web --no-tree-shake-icons --base-href "/"
docker build -t goomar_gui .
docker-compose down
docker-compose up -d
