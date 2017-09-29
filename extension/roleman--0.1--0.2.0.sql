
CREATE OR REPLACE FUNCTION mod_role(in_rolename text, in_attrs text[], mode text)
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
   IF mode NOT IN ('create', 'alter') THEN
      raise exception 'invalid mode % in mod_role', mode;
   END IF;
   IF array_upper(in_attrs, 1) > 0 THEN
       with_clause = ' WITH ' || array_to_string(in_attrs, ' ');
   END IF;
   EXECUTE upper(mode) || ' ROLE ' || quote_ident(in_rolename) || with_clause;
   return true;
END;
$$ SET SEARCH_PATH FROM CURRENT;

CREATE OR REPLACE FUNCTION create_role(IN in_rolename text, IN in_attrs text[] default '{}')
RETURNS bool LANGUAGE sql AS
$$
select roleman.mod_role(in_rolename, in_attrs, 'create');
$$ set search_path from current;

CREATE OR REPLACE FUNCTION alter_base(in_rolename text, in_attrs text[])
returns bool language sql as
$$
select roleman.mod_role(in_rolename, in_attrs, 'alter');
$$ set search_path from current;

comment on function create_role(text, text[]) is
$$Creates a role with name of rolename.  Second argument is used to provide
options for WITH clause.$$;

