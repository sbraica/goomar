#!/bin/bash
git pull
echo "BUILD FLUTTER"
cd ../gui
flutter build web --release
if [ $? -ne 0 ]; then
  printf "\n\t❌  Flutter web build failed!\n\n"
  exit 1
else
  rm build/web/index.html
  cp -r build/web/*  ../API/src/main/resources/static/login/
  printf "\n\t✅  Build copied to BE project! \n\n"
fi