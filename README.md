RoleMan:  Functions for Managing Roles in PostgreSQL
====================================================

One of the substantial difficulties with role management
in PostgreSQL from programming perspectives is that 
utility statements such as `CREATE ROLE` do not have
plans and therefore do not take parameters.  This means
that programs which want to create roles must issue the 
statements and guard against SQL injection with very little
help from the standard tools.

The roleman extension is tested in PostgreSQL 9.4 and higher.
It makes extensive use of built-in excaping functions and 
registered entity types in PostgreSQL to ensure that inputs
are handled and escaped properly regardless of inputs.

Permissions are whitelisted.

Compatibility
--------------
As of 0.1.2, installcheck works properly against 9.4 through 9.6.
There are no known or expected issues with PostgreSQL 10, but this
will be further tested.  Test case failures may need to be manually
reviewed in that case.

There are no changes to the extension between 0.1.0 and 0.1.2.
All changes are in documentation and test case compatibility.

Conventions
------------

The basic form of the argument list is:

    grantee_role, granted_object, permissions_granted

In the case of granting to all objects in a schema, we have
this divided a little more:

    grantee_role, granted_schema, granted_object_type, permissions_tranted


permissions_granted is always a whitelisted text array.  The other fields
are always singe values.

Where the granted object has a registered entity type associated
with it in all supported versions (like regclass and regprocedure)
we use that registered type.  This ensures that the object granted
is valid, and is properly escaped during the dynamic sql generation.

API Reference
---------------

 * roleman.create_role(new_rolename, [WITH attributes])
   Creates a new role.  Note that WITH does NOT support setting passwords

 * roleman.alter_base(rolename, WITH attribute)
   applies the requested WITH attributes via ALTER user.

 * roleman.set_password(rolename, password [, valid_until])
   Sets a role's password.  If valid_until is not set, it is set until 
   'infinity'

 * roleman.blank_permissions(rolename)
   Removes all permissions for a role within the current database.

 * roleman.grant_db(rolename, databasename, permissions)
   Permissions may be any of all, temp, create, and connect

 * roleman.grant_schema(rolename, schemaname, permissions)
   Permissions may be usage, create, and all

 * roleman.grant_schema_all(rolename, schemaname, object_type, permissions)
   Grants permissions ON ALL object_typw IN SCHEMA
   Permissions are whitelisted to all keywords but if you grant execute
   on a table you should expect an error

 * roleman.grant_table(rolename, tablename, permissions)
   Permissions must be all, select, update, insert, and/or delete

 * roleman.grant_function(rolename, tablename, permissions)
   permissions must be all or execute

 * roleman.grant_sequence(rolename, tablename, permissions)
   Permissions must be all or usage

 * roleman.set_guc(rolename, settingname, value)
   Sets default guc setting value for role.  Setting must
   be found in pg_settings.

 * roleman.set_guc_from_current(rolename, settingname)
   Sets the rolename's default setting (validated via pg_settings)
   to the current session value

 * roleman.set_search_path(rolename, schema_array)
   Sets the role's search_path to the schemas in the schema array.

 * roleman.set_connection_limit(rolename, connection_limit)
   A;ters the role so that the role can have no more than connection_limit
   simultaneous connections.

 * roleman.drop_role(rolename)

Major Uses
----------

 * Integrate role management functions into SQL queries.

    WITH usernames (
      select username from users WHERE username not in (select rolname from pg_roles)
    )
    select rolename.create_role(username, array['LOGIN'::text, 'NOINHERIT'])

 * Make sure that user management functions are parameterized by application

 * Allow users to change their own passwords, but expire after 90 days:

```
   CREATE FUNCTION change_my_password(in_password text) RETURNS VOID
   LANGUAGE SQL SECURITY DEFINER SET search_path=roleman
   as
   $$
   select role_change_password(session_user, in_password, ('today'::date + 90)::timestamp);
   $$;
```

Future Features
--------------

Here are some features we'd like to add to this module:

 1. Revoke rights rather than reset and rebuild
 2. Parse acl lists. 
 3. Query WITH attributes of roles
 4. ALTER ROLE .... SET x TO Y

