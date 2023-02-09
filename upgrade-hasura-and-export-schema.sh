#!/bin/sh

docker compose up -d

sleep 5

docker compose exec db sqitch --chdir db deploy

hasura_v210='hasura/graphql-engine:v2.10.2.cli-migrations-v2'
hasura_v218='hasura/graphql-engine:v2.18.0.cli-migrations-v3'

sed -i '' "s#$hasura_v210#$hasura_v218#g" docker-compose.yaml

docker compose restart graphql-engine

sleep 5

gq http://127.0.0.1:8080/v1/graphql -H 'x-hasura-admin-secret: admin' --introspect > schema.graphql
