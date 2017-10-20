SET search_path=roleman, pg_catalog, pg_temp;

ALTER FUNCTION array_lower(text[]) SET search_path FROM current;
ALTER FUNCTION mod_role(in_rolename text, in_attrs text[], mode text) SET search_path from current;
ALTER FUNCTION create_role(IN in_rolename text, IN in_attrs text[]) SET search_path from current;
ALTER FUNCTION alter_base(in_rolename text, in_attrs text[]) SET search_path from current;
ALTER FUNCTION role_set_password (text, text, timestamp) SET search_path from current;
ALTER FUNCTION role_blank_perms(in_rolename text) SET search_path from current;
ALTER function grant_database(in_rolename text, in_dbname text, in_perms text[]) SET search_path from current;
ALTER function grant_schema(in_rolename text, in_schema text, in_perms text[]) SET search_path from current;
ALTER function grant_schema_all(in_rolename text, in_schema text, in_type text, in_perms text[]) SET search_path from current;
ALTER function grant_table(in_rolename text, in_table regclass, in_perms text[]) SET search_path from current;
ALTER function grant_seq(in_rolename text, in_seq regclass, in_perms text[]) SET search_path from current;
ALTER function grant_function(in_rolename text, in_proc regprocedure, in_perms text[]) SET search_path from current;
ALTER function role_grant_role(in_rolename text, in_new_parent text) SET search_path from current;
ALTER FUNCTION drop_role(in_rolename text) SET search_path from current;

CREATE FUNCTION validate_setting(in_setting_name text)
returns void language plpgsql as
$$
begin
   -- No quoting permitted here so it is needed to check here for valid names.
   PERFORM * FROM pg_settings WHERE name = lower(in_setting_name);
   IF NOT FOUND THEN
       RAISE EXCEPTION 'Setting "%" does not exist', in_setting_name;
   END IF;
end;
$$ SET SEARCH_PATH FROM CURRENT;

CREATE OR REPLACE FUNCTION set_guc(in_rolename text, in_setting_name text, in_setting_value text)
returns void language plpgsql as
$$
BEGIN
   perform validate_setting(in_setting_name);
   EXECUTE 'ALTER USER ' || quote_ident(in_rolename) 
            || ' SET ' || in_setting_name 
            || ' TO ' || quote_ident(in_setting_value);
END;
$$ SET SEARCH_PATH FROM CURRENT;

CREATE OR REPLACE FUNCTION set_guc_from_current(in_rolename text, in_setting_name text)
returns void language plpgsql as
$$
BEGIN
   perform validate_setting(in_setting_name);
   EXECUTE 'ALTER USER ' || quote_ident(in_rolename) 
            || ' SET ' || in_setting_name || ' FROM CURRENT';
END;
$$ SET SEARCH_PATH FROM CURRENT;

CREATE OR REPLACE FUNCTION reset_guc(in_rolename text, in_setting_name text)
returns void language plpgsql as
$$
BEGIN
   perform validate_setting(in_setting_name);
   EXECUTE 'ALTER USER ' || quote_ident(in_rolename) 
            || ' SET ' || in_setting_name || ' FROM CURRENT';
END;
$$ SET SEARCH_PATH FROM CURRENT;



CREATE OR REPLACE FUNCTION set_connection_limit(in_rolename text, in_connection_limit int)
returns void language plpgsql as
$$
BEGIN
   EXECUTE 'ALTER ROLE ' || quote_ident(in_rolename) || ' WITH CONNECTION LIMIT ' || in_connection_limit;
END;
$$ SET SEARCH_PATH FROM CURRENT;

CREATE OR REPLACE FUNCTION set_search_path(in_rolename text, in_schemalist text[])
returns void language plpgsql as
$$
DECLARE schemalist text;
BEGIN
   SELECT array_to_string(array_agg(quote_ident(s)), ', ') INTO schemalist FROM unnest(in_schemalist) s;
   EXECUTE 'ALTER ROLE ' || quote_ident(in_rolename) || ' SET SEARCH_PATH TO ' || schemalist;
END;
$$ SET SEARCH_PATH FROM CURRENT;
