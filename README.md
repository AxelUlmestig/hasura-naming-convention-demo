### Introduction

The naming convention for Hasura's generated graphql schema seems to have
changed somewhere between v2.10 and v2.18. The fields for ordering on
aggregates go from PascalCase to snake_case.

Exporting the schema in v2.10 will generate fields looking like this:
```gql
input FriendsAggregateOrderBy {
  ...
  max: FriendsMaxOrderBy
}
```

Applying the same data to v2.18 and then exporting you get this:
```gql
input FriendsAggregateOrderBy {
  ...
  max: friends_max_order_by
}
```

### Steps to reproduce

##### Database setup
This project contains a small demo database with the following table
```sql
create table friends (
  id serial not null primary key,
  name text not null,
  age smallint not null,
  best_friend_id int references friends(id)
);
```

The table has an array relation to itself to track "best friends":
```yaml
table:
  name: friends
  schema: public
array_relationships:
  - name: bestFriends
    using:
      foreign_key_constraint_on:
        column: best_friend_id
        table:
          name: friends
          schema: public
```

##### Exporting the schema

- Start the containers: `docker-compose up -d`

The following steps can be run using a script:
```sh
./upgrade-hasura-and-export-schema.sh
```

OR by going through the steps manually:

- Make sure that `gq` is installed (`npm install -g graphqurl`).
- Start the containers: `docker-compose up -d`
- Apply database migrations: `docker compose exec db sqitch --chdir db deploy`
- Apply Hasura metadata: `docker compose exec graphql-engine hasura-cli --project /hasura-config metadata apply`
- Export the graphql schema: `gq http://127.0.0.1:8080/v1/graphql -H 'x-hasura-admin-secret: admin' --introspect > schema.graphql`
- Verify that nothing has changed: `git diff schema.graphql`
- Update the hasura version:
  ```
  hasura_v210='hasura/graphql-engine:v2.10.2.cli-migrations-v2'
  hasura_v218='hasura/graphql-engine:v2.18.0.cli-migrations-v3'
  
  sed -i '' "s#$hasura_v210#$hasura_v218#g" docker-compose.yaml
  ```
- Restart the containers with to get the new version: `docker compose down; docker compose up -d`
- Export the schema again: `gq http://127.0.0.1:8080/v1/graphql -H 'x-hasura-admin-secret: admin' --introspect > schema.graphql`
- Check the diff: `git diff schema.graphql`

##### Expected results

The `schema.graphql` file shouldn't change much

##### Actual results

The fields related to ordering by aggregates change from PascalCase to
snake_case. E.g.

```gql
input FriendsAggregateOrderBy {
  ...
  max: FriendsMaxOrderBy
}
```

becomes
```gql
input FriendsAggregateOrderBy {
  ...
  max: friends_max_order_by
}
```
