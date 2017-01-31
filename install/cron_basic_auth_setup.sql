-- We create a database schema especially for auth information. We'll also need the postgres extension pgcrypto.
-- needs to be run on correct DB !!!

-- First we’ll need a table to keep track of our users:
-- We put things inside the basic_auth schema to hide
-- them from public view. Certain public procs/views will
-- refer to helpers and tables inside.
create schema if not exists basic_auth;

create table if not exists
basic_auth.users (
  email    text primary key check ( email ~* '^.+@.+\..+$' ),
  pass     text not null check (length(pass) < 512),
  role     name not null check (length(role) < 512)
);

-- We would like the role to be a foreign key to actual database roles, however PostgreSQL does not support these constraints against the pg_roles table. We’ll use a trigger to manually enforce it.

create or replace function
basic_auth.check_role_exists() returns trigger
  language plpgsql
  as $$
begin
  if not exists (select 1 from pg_roles as r where r.rolname = new.role) then
    raise foreign_key_violation using message =
      'unknown database role: ' || new.role;
    return null;
  end if;
  return new;
end
$$;

drop trigger if exists ensure_user_role_exists on basic_auth.users;
create constraint trigger ensure_user_role_exists
  after insert or update on basic_auth.users
  for each row
  execute procedure basic_auth.check_role_exists();

-- Next we’ll use the pgcrypto extension and a trigger to keep passwords safe in the users table.

create extension if not exists pgcrypto;
create extension if not exists pgjwt;

create or replace function
basic_auth.encrypt_pass() returns trigger
  language plpgsql
  as $$
begin
  if tg_op = 'INSERT' or new.pass <> old.pass then
    new.pass = crypt(new.pass, gen_salt('bf'));
  end if;
  return new;
end
$$;

drop trigger if exists encrypt_pass on basic_auth.users;
 create trigger encrypt_pass
   before insert or update on basic_auth.users
   for each row
   execute procedure basic_auth.encrypt_pass();

-- With the table in place we can make a helper to check a password against the encrypted column. It returns the database role for a user if the email and password are correct.

create or replace function
basic_auth.user_role(email text, pass text) returns name
  language plpgsql
  as $$
begin
  return (
  select role from basic_auth.users
   where users.email = user_role.email
     and users.pass = crypt(user_role.pass, users.pass)
  );
end;
$$;

--Logins

-- As described in JWT from SQL, we’ll create a JWT inside our login function. Note that you’ll need to adjust the secret key which is hard-coded in this example to a secure secret of your choosing.

CREATE TYPE basic_auth.jwt_token AS (
  token text
);

create or replace function
login(email text, pass text) returns basic_auth.jwt_token
  language plpgsql
  as $$
declare
  _role name;
  result basic_auth.jwt_token;
begin
  -- check email and password
  select basic_auth.user_role(email, pass) into _role;
  if _role is null then
    raise invalid_password using message = 'invalid user or password';
  end if;

  select sign(
      row_to_json(r), 'example_secret'
    ) as token
    from (
      select _role as role, login.email as email,
         extract(epoch from now())::integer + 60*60 as exp
    ) r
    into result;
  return result;
end;
$$;

-- Permissions
-- Your database roles need access to the schema, tables, views and functions
-- in order to service HTTP requests. Recall from the Overview of Role System
--that PostgREST uses special roles to process requests, namely the authenticator
-- and anonymous roles. Below is an example of permissions that allow anonymous
-- users to create accounts and attempt to log in.
-- the names "anon" and "authenticator" are configurable and not
-- sacred, we simply choose them for clarity
create role anon;
create role authenticator noinherit;
grant anon to authenticator;
grant usage on schema basic_auth to anon;
-- grant usage on schema basic_auth to anon;
grant select on table pg_authid, basic_auth.users to anon;
grant execute on function login(text,text) to anon;
CREATE ROLE author NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;
GRANT author TO authenticator;
grant usage on schema public, basic_auth to author;
