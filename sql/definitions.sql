set client_min_messages to warning;
set log_error_verbosity to terse;
create extension roleman;

-- whitelist errors

-- no tables so pick a random number and cast to oid
select roleman.grant_table('postgres', 1::oid, array['execute', 'drop']);
select roleman.grant_schema('postgres', 'foo', array['execute']);
select roleman.grant_schema_all('postgres', 'foo', 'tables', array['execute', 'drop everything']);
select roleman.grant_database('postgres', 'foo', array['execute']);
select roleman.grant_function('postgres', 1::OID, array['wheeee']);
select roleman.grant_seq('postgres', 1::oid, array['execute']);

create schema testing;
create table testing.foo(id int);
create table testing."foo(id int)"" drop table testing.foo; --"(id int); 
create table testing."foo(id int)' drop table testing.foo; --"(id int); 

insert into testing.foo values (1);
insert into  testing."foo(id int)"" drop table testing.foo; --" values (2); 
insert into testing."foo(id int)' drop table testing.foo; --" values (3); 

create schema "testing; drop table testing.foo; --";
create table "testing; drop table testing.foo; --".foo();
create schema "testing'; drop table testing.foo; --";
create table "testing'; drop table testing.foo; --".foo();
create schema "testing""; drop table testing.foo; --";
create table "testing""; drop table testing.foo; --".foo();

create sequence testing."foo1"" drop table testing.foo; --";

create function testing.foo(testing."foo(id int)"" drop table testing.foo; --", testing."foo(id int)' drop table testing.foo; --")
returns bool language sql as $$ select true; $$;

create schema testing2;
create table testing2.foo(id int);

create schema testing3;
create table testing3.foo(id int);

-- Create roles for Bobby Tables
-- die with error
select roleman.create_role('bobby"; drop table testing.foo; --', array['login', 'password ''foo''']);

-- succeed
select roleman.create_role('bobby"; drop table testing.foo; --', array['login', 'noinherit']);
select roleman.create_role('bobby_tables"; foo', array['inherit', 'nologin']);
select roleman.create_role('bobby''; drop table testing.foo; --');

-- succeed no perms
select roleman.role_blank_perms('bobby"; drop table testing.foo; --');

set role "bobby'; drop table testing.foo; --";

-- permission denied errors
select * from testing.foo;
select * from testing.foo(null, null);

reset role;

select roleman.grant_schema(r, s, array['all'])
  FROM unnest(array['bobby"; drop table testing.foo; --'::text, 'bobby_tables"; foo', 'bobby''; drop table testing.foo; --']) r
  cross join unnest (array['testing', 'testing''; drop table testing.foo; --', 'testing; drop table testing.foo; --', 'testing"; drop table testing.foo; --']) s;

select roleman.grant_table(r, t.oid::regclass, array['select'])
  FROM unnest(array['bobby"; drop table testing.foo; --'::text, 'bobby_tables"; foo', 'bobby''; drop table testing.foo; --']) r
 CROSS JOIN
       pg_class t
 WHERE t.relname like '%--%' and t.relkind = 'r';

SET ROLE "bobby'; drop table testing.foo; --";
select * from  testing."foo(id int)"" drop table testing.foo; --"; 
select * from testing."foo(id int)' drop table testing.foo; --"; 
SELECT * FROM testing.foo;
RESET ROLE;

SET ROLE "bobby_tables""; foo";
select * from  testing."foo(id int)"" drop table testing.foo; --"; 
select * from testing."foo(id int)' drop table testing.foo; --"; 
SELECT * FROM testing.foo;
RESET ROLE;

SET ROLE "bobby""; drop table testing.foo; --";
select * from  testing."foo(id int)"" drop table testing.foo; --"; 
select * from testing."foo(id int)' drop table testing.foo; --"; 
SELECT * FROM testing.foo;
RESET ROLE;

select roleman.grant_schema_all(r, s, 'table', array['select'])
  FROM unnest(array['bobby"; drop table testing.foo; --'::text, 'bobby_tables"; foo', 'bobby''; drop table testing.foo; --']) r
  cross join unnest (array['testing''; drop table testing.foo; --', 'testing; drop table testing.foo; --', 'testing"; drop table testing.foo; --']) s;

SET ROLE "bobby'; drop table testing.foo; --";
select * from  testing."foo(id int)"" drop table testing.foo; --"; 
select * from testing."foo(id int)' drop table testing.foo; --"; 
SELECT * FROM testing.foo;
RESET ROLE;

SET ROLE "bobby_tables""; foo";
select * from  testing."foo(id int)"" drop table testing.foo; --"; 
select * from testing."foo(id int)' drop table testing.foo; --"; 
SELECT * FROM testing.foo;
RESET ROLE;

SET ROLE "bobby""; drop table testing.foo; --";
select * from  testing."foo(id int)"" drop table testing.foo; --"; 
select * from testing."foo(id int)' drop table testing.foo; --"; 
SELECT * FROM testing.foo;
RESET ROLE;

select roleman.grant_function(r, testing.foo::regproc::oid::regprocedure, array['execute']))
  FROM unnest(array['bobby"; drop table testing.foo; --'::text, 'bobby_tables"; foo', 'bobby''; drop table testing.foo; --']) r;

SET ROLE "bobby'; drop table testing.foo; --";
select * from  testing."foo(id int)"" drop table testing.foo; --"; 
reset role;

select roleman.role_blank_perms('bobby"; drop table testing.foo; --');
select roleman.drop_role('bobby"; drop table testing.foo; --');
select roleman.role_blank_perms('bobby''; drop table testing.foo; --');
select roleman.drop_role('bobby''; drop table testing.foo; --');
select roleman.role_blank_perms('bobby_tables"; foo');
select roleman.drop_role('bobby_tables"; foo');



select 'testing.foo'::regclass::text;
