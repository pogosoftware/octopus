#!/bin/bash

pushd /vagrant/scripts/octopus-server

mkdir -p /vagrant/secrets

echo "Generating MSSQL user password..."
export SA_PASSWORD=`openssl rand -base64 24`
echo $SA_PASSWORD > /vagrant/secrets/sa_password

echo "Generating Octopus user password..."
export ADMIN_PASSWORD=`openssl rand -base64 24`
echo $ADMIN_PASSWORD > /vagrant/secrets/admin_password

echo "Pulling MSSQL docker image..."
docker pull mcr.microsoft.com/mssql/server:2017-CU20-ubuntu-16.04

echo "Pulling OctopusDeploy docker image..."
docker pull octopusdeploy/octopusdeploy:2020.3.4

echo "Run MSSQL and OctopusDeploy"
docker-compose --project-name Octopus up -d

popd >/dev/null

unset SA_PASSWORD
unset ADMIN_PASSWORD

echo "Waiting to Octopus Server to be running..."
sleep 30s
OCTOPUS_ID=`docker ps --filter "label=app=octopus" --format "{{.ID}}"`
HEALTH_STATUS=`docker inspect $OCTOPUS_ID | jq --raw-output '.[].State.Health.Status'`
while [ "$HEALTH_STATUS" != "healthy" ] ; do
    sleep 10s
    HEALTH_STATUS=`docker inspect $OCTOPUS_ID | jq --raw-output '.[].State.Health.Status'`
done

echo "Exporting Master Key..."
docker exec -it $OCTOPUS_ID ./Octopus.Server show-master-key > /vagrant/secrets/master_key