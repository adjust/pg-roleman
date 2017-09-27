CREATE FUNCTION array_lower(in_array text[])
returns text[]
language sql immutable as
$$
select string_to_array(lower(array_to_string(in_array, ':~:')), ':~:');
$$;

comment on function array_lower(text[]) is
$$Takes in an array of text elements and returns
an array of text elements in lower case.  Intended for use
with whitelisting SQL keywords, so elements must not contain
the string ':~:'$$;

CREATE OR REPLACE FUNCTION create_role(IN in_rolename text, IN in_attrs text[] default '{}')
RETURNS bool LANGUAGE plpgsql as
$$
DECLARE with_clause text = '';
BEGIN
   IF not (array_lower(in_attrs) 
           <@ 
          array['superuser'::text, 'replication', 'login', 'inherit', 'nologin', 'noinherit',
                'nosuperuser', 'nocreatedb', 'noreplication', 'createdb', 'createrole',
                'nocreaterole'])
   THEN RAISE EXCEPTION 'Bad option for role %, options were %', in_rolename, 
          array_to_string(in_attrs, ', ');
   END IF;
   IF array_upper(in_attrs, 1) > 0 THEN
       with_clause = ' WITH ' || array_to_string(in_attrs, ' ');
   END IF;
   EXECUTE 'CREATE ROLE ' || quote_ident(in_rolename) || with_clause;
   return true;
END;
$$ SET SEARCH_PATH FROM CURRENT;

comment on function create_role(text, text[]) is
$$Creates a role with name of rolename.  Second argument is used to provide
options for WITH clause.$$;

CREATE OR REPLACE FUNCTION role_set_password
(in_rolename text, in_password text, in_valid_until timestamp default 'infinity')
RETURNS void language plpgsql as
$$
BEGIN
   EXECUTE 'alter role ' || quote_ident(in_rolename) 
            || ' with password ' || quote_literal(in_password)
            || ' valid until ' || quote_literal(in_valid_until);
END;
$$ SET SEARCH_PATH FROM CURRENT;;

CREATE OR REPLACE FUNCTION role_blank_perms(in_rolename text)
RETURNS BOOL 
language plpgsql as $$
DECLARE permrec record;
        acltype text;
BEGIN
   PERFORM FROM pg_roles where rolname = in_rolename;
   IF NOT FOUND THEN RETURN FALSE; END IF;
   -- ok now we look for all db objects with explicit permissions and revoke all from them.
   -- These may be overinclusive but better that than under-inclusive.

   -- revoke all from current database
   EXECUTE 'REVOKE ALL ON DATABASE ' || quote_ident(current_database()) || ' FROM ' || quote_ident(in_rolename);

   FOR permrec IN SELECT oid, * FROM pg_namespace
   LOOP
      EXECUTE 'REVOKE ALL ON ALL TABLES IN SCHEMA ' || quote_ident(permrec.nspname) || ' FROM ' || quote_ident(in_rolename);
      EXECUTE 'REVOKE ALL ON ALL SEQUENCES IN SCHEMA ' || quote_ident(permrec.nspname) || ' FROM ' || quote_ident(in_rolename);
      EXECUTE 'REVOKE ALL ON ALL FUNCTIONS IN SCHEMA ' || quote_ident(permrec.nspname) || ' FROM ' || quote_ident(in_rolename);
      EXECUTE 'REVOKE ALL ON SCHEMA ' || quote_ident(permrec.nspname) || ' FROM ' || quote_ident(in_rolename);
   END LOOP;

   -- finally roles we have been granted
   FOR permrec IN 
       SELECT mr.*
         FROM pg_auth_members m
         JOIN pg_roles mr ON m.roleid = mr.oid
         join pg_roles pr ON m.member = pr.oid
              and pr.rolname = in_rolename
   LOOP
       EXECUTE 'REVOKE ' || quote_ident(permrec.rolename) || ' FROM ' || quote_ident(in_rolename);
   END LOOP;
   RETURN TRUE; 
END;
$$ SET SEARCH_PATH FROM CURRENT;;

create or replace function grant_database(in_rolename text, in_dbname text, in_perms text[])
RETURNS VOID LANGUAGE PLPGSQL AS
$$
BEGIN
   IF NOT (array_lower(in_perms) <@ ARRAY['connect', 'create', 'temp', 'temporary', 'all']) then
      RAISE EXCEPTION 'bad database permissions for %, dbname %, perms %',
            in_rolename, in_dbname, array_to_string(in_perms, ', ');
   END IF;
   EXECUTE 'GRANT ' || array_to_string(in_perms, ', ') || ' on database ' 
          || quote_ident(in_dbname) || ' TO ' || quote_ident(in_rolename);
END;
$$ SET SEARCH_PATH FROM CURRENT;;

create or replace function grant_schema(in_rolename text, in_schema text, in_perms text[])
RETURNS VOID LANGUAGE PLPGSQL AS
$$
BEGIN
   IF NOT (array_lower(in_perms) <@ ARRAY['usage', 'create', 'all']) then
      RAISE EXCEPTION 'bad permissions for %,  schema %, perms %',
            in_rolename, in_schema, array_to_string(in_perms, ', ');
   END IF;
   EXECUTE 'GRANT ' || array_to_string(in_perms, ', ') || ' on schema ' 
          || quote_ident(in_schema) || ' TO ' || quote_ident(in_rolename);
END;
$$ SET SEARCH_PATH FROM CURRENT;

create or replace function grant_schema_all(in_rolename text, in_schema text, in_type text, in_perms text[])
RETURNS VOID LANGUAGE PLPGSQL AS
$$
BEGIN
   IF NOT (array_lower(in_perms) <@ ARRAY['usage', 'create', 'all', 'select', 
                                         'update', 'insert', 'delete', 'execute']) then
      RAISE EXCEPTION 'bad database permissions for %,  schema %, type %, perms %',
            in_rolename, in_schema, in_type, array_to_string(in_perms, ', ');
   END IF;
   IF NOT lower(in_type) = any(ARRAY['functions', 'tables', 'sequences']) THEN
      RAISE EXCEPTION 'bad tyoe %', in_type;
   END IF;
   EXECUTE 'GRANT ' || array_to_string(in_perms, ', ') || ' on all '|| in_type || ' in schema ' 
          || quote_ident(in_schema) || ' TO ' || quote_ident(in_rolename);
END;
$$ SET SEARCH_PATH FROM CURRENT;

create or replace function grant_table(in_rolename text, in_table regclass, in_perms text[])
RETURNS VOID LANGUAGE PLPGSQL AS
$$
BEGIN
   IF NOT (array_lower(in_perms) <@ ARRAY['select', 'insert', 'update', 'delete', 'all']) then
      RAISE EXCEPTION 'bad database permissions for %,  table %, perms %',
            in_rolename, in_table, array_to_string(in_perms, ', ');
   END IF;
   EXECUTE 'GRANT ' || array_to_string(in_perms, ', ') || ' on table ' 
          || in_table || ' TO ' || quote_ident(in_rolename);
END;
$$ SET SEARCH_PATH FROM CURRENT;

create or replace function grant_seq(in_rolename text, in_seq regclass, in_perms text[])
RETURNS VOID LANGUAGE PLPGSQL AS
$$
BEGIN
   IF NOT (array_lower(in_perms) <@ ARRAY['usage', 'all']) then
      RAISE EXCEPTION 'bad database permissions for %,  sequence %, perms %',
            in_rolename, in_seq, array_to_string(in_perms, ', ');
   END IF;
   EXECUTE 'GRANT ' || array_to_string(in_perms, ', ') || ' on sequence ' 
          || in_seq || ' TO ' || quote_ident(in_rolename);
END;
$$ SET SEARCH_PATH FROM CURRENT;

create or replace function grant_function(in_rolename text, in_proc regprocedure, in_perms text[])
RETURNS VOID LANGUAGE PLPGSQL AS
$$
BEGIN
   IF NOT (array_lower(in_perms) <@ ARRAY['execute', 'all']) then
      RAISE EXCEPTION 'bad database permissions for %,  function %, perms %',
            in_rolename, in_proc, array_to_string(in_perms, ', ');
   END IF;
   EXECUTE 'GRANT ' || array_to_string(in_perms, ', ') || ' on function  ' 
          || in_proc || ' TO ' || quote_ident(in_rolename);
END;
$$ SET SEARCH_PATH FROM CURRENT;

create or replace function role_grant_role(in_rolename text, in_new_parent text)
returns void language plpgsql as
$$
begin
   EXECUTE 'grant ' || quote_ident(in_new_parent) || ' to ' || quote_ident(in_rolename);
END;
$$ SET SEARCH_PATH FROM CURRENT;

CREATE OR REPLACE FUNCTION drop_role(in_rolename text)
RETURNS VOID LANGUAGE PLPGSQL AS
$$
BEGIN
   EXECUTE 'DROP ROLE ' || quote_ident(in_rolename);
END;
$$;
