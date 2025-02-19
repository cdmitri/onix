#!/bin/bash

echo "===================================================="
echo "Stopping all Onix containers ..."
# NB. Don't rely on Docker Compose here as potential lack of .env file blocks dc down
docker rm \
  evr-mongo-dbgui \
  evr-mongo-db \
  evr-mongo-app \
  db \
  db-gui \
  artreg-app \
  ox-app \
  ox-dbman \
  pilotctl-dbman \
  pilotctl-app \
  nexus \
  -f

echo "===================================================="
echo "Destroying Docker volumes ..."
docker volume rm \
  evr-mongo-db \
  evr-mongo-dblogs \
  db \
  dbgui \
  nexus

echo "===================================================="
echo "Destroying local Onix configuration ..."
rm ${HOME}/.config/onix -rf
