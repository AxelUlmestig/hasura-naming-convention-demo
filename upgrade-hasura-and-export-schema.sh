#!/bin/sh

docker compose up -d

echo "waiting 5 seconds for Hasura to start..."
sleep 5

# deploy the database to make sure tables exist
docker compose exec db sqitch --chdir db deploy

# apply the Hasura metadata, it takes quite some time for Hasura to start up,
# this might take a while
docker compose exec graphql-engine hasura-cli --project /hasura-config metadata apply
while [ $? -ne 0 ]
do
  sleep 1;
  echo "failed to apply metadata, trying again in one second..."
  docker compose exec graphql-engine hasura-cli --project /hasura-config metadata apply
done

# replace the Hasura version in docker compose and restart the container
hasura_v210='hasura/graphql-engine:v2.10.2.cli-migrations-v2'
hasura_v218='hasura/graphql-engine:v2.18.0.cli-migrations-v3'

sed -i '' "s#$hasura_v210#$hasura_v218#g" docker-compose.yaml

docker compose down
docker compose up -d

echo "waiting 10 seconds for Hasura to restart..."
sleep 10

# export the schema
# This relies on `gq` being installed. Run `npm install -g graphqurl` if it's not installed
gq http://127.0.0.1:8080/v1/graphql -H 'x-hasura-admin-secret: admin' --introspect > schema.graphql
