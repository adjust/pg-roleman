RomeMan:  Functions for Managing Roles in PostgreSQL
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
