-- Deploy hasura-test:tables to pg

BEGIN;

create table friends (
  id serial not null primary key,
  name text not null,
  age smallint not null,
  best_friend_id int references friends(id)
);

COMMIT;
