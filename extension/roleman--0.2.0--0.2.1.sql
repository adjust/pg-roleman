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
