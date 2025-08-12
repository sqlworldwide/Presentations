/*
Written by: Taiob Ali
Date: August 19, 2025
On Tour Pass Summit in New York City
*/

/********************
* DEMO SECTION ONE  *
********************/

/*
Connect to the localhost:54990/postgres database with user postgres
psql -h 127.0.0.2 -p 54990 -U postgres -d postgres
\conninfo is a psql command to check what database and role you are connected to
postgres user is the default superuser in PostgreSQL

To check the current password encryption method in PostgreSQL:
SHOW password_encryption;
*/
-- DROP DATABASE nyctourdemo if it exists
DROP DATABASE IF EXISTS nyctourdemo;
-- Create a new database named nyctourdemo
CREATE DATABASE nyctourdemo;
--Change connection to nyctourdemo database

/*
This statement creates two new roles named 'devlogin' and 'readlogin' with login privileges and a password.
This is the same as 
CREATE USER devlogin WITH PASSWORD 'devlogin';
*/
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'devlogin') THEN
        DROP ROLE devlogin;
    END IF;
END $$;
CREATE ROLE devlogin WITH LOGIN PASSWORD 'devlogin';
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'readlogin') THEN
        DROP ROLE readlogin;
    END IF;
END $$;
CREATE ROLE readlogin WITH LOGIN PASSWORD 'readlogin';

/*
Default privileges granted to all roles:
 ->CONNECT
 ->TEMPORARY
 ->EXECUTE (functions and procedures)
 ->USAGE (domains, languages, and types)

Read more about 'SET ROLE' in PostgreSQL:
https://www.postgresql.org/docs/current/sql-set-role.html
*/

/*
 Switch to the devlogin role
 SET ROLE command sets the current user identifier of the current SQL session to be role_name.
*/

SET ROLE devlogin;
SELECT SESSION_USER, CURRENT_USER;

DROP TABLE IF EXISTS test_table;
CREATE TABLE public.test_table (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL
);
--SET ROLE NONE sets the current user identifier to the current session user identifier, as returned by session_user
SET ROLE NONE;
SELECT SESSION_USER, CURRENT_USER;


/*
We have issues:
The devlogin role does not have the CREATE privilege on the database.
To fix this, we need to grant the proper privilege to the devlogin role
*/

-- Grant schema privileges (for creating new objects) to devlogin.
GRANT ALL ON SCHEMA public TO devlogin;
-- Grant privileges on existing objects within the public schema.
GRANT ALL ON ALL TABLES IN SCHEMA public TO devlogin;

-- Lets try again
SET ROLE devlogin;
DROP TABLE IF EXISTS test_table;
CREATE TABLE test_table (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL
);
SET ROLE NONE;

/*
Read from the table using readlogin role
The readlogin role does not have the SELECT privilege on the test_table
Why?
Read line 83
*/
SET ROLE readlogin;
SELECT * FROM test_table LIMIT 10;
SET ROLE NONE;

-- Grant SELECT privilege on the test_table to readlogin role
GRANT SELECT ON test_table TO readlogin;

--Try reading the table again
SET ROLE readlogin;
SELECT * FROM test_table LIMIT 10;
SET ROLE NONE;

/*
Now if the devlogin role creates a new table, 
do you think readlogin will be able to read from it?
Let's try it out.
*/
SET ROLE devlogin;
DROP TABLE IF EXISTS test_table2;
CREATE TABLE test_table2 (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL
);
SET ROLE NONE;

SET ROLE readlogin;
SELECT * FROM test_table2 LIMIT 10;
SET ROLE NONE;

/*
Why did it fail?
The readlogin role cannot read from the test_table2; created by the devlogin role because it does not have the SELECT privilege on this new table.
To fix this, we need to grant the SELECT privilege on the new table to the readlogin role.
GRANT SELECT ON test_table2 TO readlogin;

As you can see, this will become very cumbersome as you will need to grant privileges to each new object to each role based on the operations they need to perform.
In a large application, you will have many roles and many objects (tables, views, etc.), and managing privileges this way can become a nightmare.
We will look at how to manage privileges more efficiently in the Demo II section.
Back to slides for now!!
*/

/********************
* DEMO SECTION TWO  *
********************/

/*
Connect to the nyctourdemo database
We can create groups (similar to SQL Server roles) in PostgreSQL to manage privileges more efficiently.
To create a group role in PostgreSQL, you can use the CREATE ROLE command with the NOLOGIN option.
CREATE GROUP is now an alias for CREATE ROLE.
*/
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'devgroup') THEN
        DROP ROLE devgroup;
    END IF;
END $$;
CREATE ROLE devgroup NOLOGIN;

-- Now we can grant privileges to this group role
GRANT CREATE ON SCHEMA public TO devgroup;  

-- Add devlogin (user) to the devgroup (group role)
GRANT devgroup TO devlogin;  

-- Assume we have new developer that also needs to create tables in the public schema
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'devlogin2') THEN
        DROP ROLE devlogin2;
    END IF;
END $$;
CREATE ROLE devlogin2 WITH LOGIN PASSWORD 'devlogin2';

-- Add devlogin2 to the devgroup
GRANT devgroup TO devlogin2;

-- Now devlogin2 can create tables in the public schema without needing to grant privileges explicitly
DROP TABLE IF EXISTS test_table3;
SET ROLE devlogin2;
CREATE TABLE test_table3 (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL
);
SET ROLE NONE;

/*
Create a group role for read-only users
Remember that this also does not solve our problem of granting privileges on new objects.
We still need to grant privileges on each new object to the read-only group role.
We will deal with it later in this demo.
*/
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'readonlygroup') THEN
        DROP ROLE readonlygroup;
    END IF;
END $$;
CREATE ROLE readonlygroup NOLOGIN;

-- Now we can grant privileges to this group role readonlygroup
-- Allows all members of readonlygroup to SELECT from all existing tables within the public schema.
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonlygroup;

-- Add readlogin to the readonlygroup
GRANT readonlygroup TO readlogin;

-- Assume we have a new read-only user that needs to read from the public schema
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'readlogin2') THEN
        DROP ROLE readlogin2;
    END IF;
END $$;
CREATE ROLE readlogin2 WITH LOGIN PASSWORD 'readlogin2';
GRANT readonlygroup TO readlogin2;

-- Now readlogin2 can read from the public schema without needing to grant privileges explicitly
SET ROLE readlogin2;    
SELECT * FROM test_table3 LIMIT 10;
SET ROLE NONE;  

/*
How do we solve the problem of granting privileges on new objects?
We can use the ALTER DEFAULT PRIVILEGES command to set default privileges for new objects created in a schema.
This way, any new objects created in the schema will automatically have the specified privileges granted to the specified roles.
In order to define default privileges, you need to be the owner of the objects or a superuser.

Ownership of an object in PostgreSQL is determined by the role that created it. 
By default, the creator of an object is its owner.
The following is copied from https://www.postgresql.org/docs/current/sql-alterdefaultprivileges.html written by Ryan Booz.

There are three major points you need to understand about object ownership:

Only a superuser or the owner of an object (table, function, procedure, sequence, etc.) can ALTER/DROP the object.
Only a superuser or the owner of an object can ALTER the ownership of that object.
Only the owner of an object can define default privileges for the objects they create.
*/

--who owns the test_table3?
SELECT tablename, tableowner
FROM pg_tables
WHERE tablename = 'test_table3';

-- See an example why table ownership matters in PostgreSQL
-- We know that devlogin2 is a member of devlogin.
SET ROLE devlogin;
ALTER TABLE test_table3
ADD COLUMN description TEXT;
SET ROLE NONE;

/*
Reasonable solution to solve this problem is to set the ownership of all objects to a role.
That way all members of that role can alter the objects.
Going forward, create all objects with the devgroup as the owner
*/
-- Set the owner of the test_table3 to devgroup
SET ROLE devlogin2;
ALTER TABLE test_table3 OWNER TO devgroup;
SET ROLE NONE;

SET ROLE devlogin;
ALTER TABLE test_table3
ADD COLUMN description TEXT;
SET ROLE NONE;

--Let's change the ownership of the other two tables before we set default privileges
SET ROLE devlogin;
ALTER TABLE test_table OWNER TO devgroup;
ALTER TABLE test_table2 OWNER TO devgroup;
SET ROLE NONE;

-- Check the ownership of the tables
SELECT tablename, tableowner
FROM pg_tables
WHERE schemaname = 'public';

-- Check current default privileges using psql
-- \ddp


-- Set default privileges for the readonlygroup role, so all new tables created in the public schema will have SELECT privilege granted to readonlygroup
SET ROLE devgroup;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT SELECT ON TABLES TO readonlygroup;
SET ROLE NONE;

-- Check current default privileges using psql
-- \ddp

/*
Create a new table as the devgroup role
This table will automatically have SELECT privilege granted to readonlygroup role
*/
SET ROLE devgroup;
DROP TABLE IF EXISTS test_table4;
CREATE TABLE test_table4 (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL
);
SET ROLE NONE;

SET ROLE readlogin;
SELECT * FROM test_table4 LIMIT 10; 
SET ROLE NONE;

/*
We can create other groups with different sets of default privileges.
For example, we can create a group for developers that need to create and modify objects.
A group with execute privileges on functions and procedures.
*/

/*
In SQL Server we will use fixed database roles to give permissions to create and read from tables.
What will happen if we create another database can we reuse the roles we created in the first database?
Let's find out.
*/
-- DROP DATABASE nyctourdemo2 if it exists
DROP DATABASE IF EXISTS nyctourdemo2;
-- Create a new database named nyctourdemo2
CREATE DATABASE nyctourdemo2;
--Change connection to nyctourdemo2 database

-- Create a new table
-- NOTE: After creating a new database, you must re-grant schema and table privileges because privileges are database-specific in PostgreSQL, even though roles are cluster-wide.
SET ROLE devgroup;
CREATE TABLE test_table5 (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL
);
SET ROLE NONE;

/*
Why did the create statement failed?
Fundamental concept in PostgreSQL: roles are cluster-wide, but privileges are database-specific.
*/

-- Grant schema privileges (for creating new objects) to devgroup.
GRANT ALL ON SCHEMA public TO devgroup;
-- Grant privileges on existing objects within the public schema.
GRANT ALL ON ALL TABLES IN SCHEMA public TO devgroup;

-- Create a new table
SET ROLE devgroup;
CREATE TABLE test_table5 (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL
);
SET ROLE NONE;

/*
We can repeat the same for other groups like readonlygroup.
But how do we get around this limitation, if we are always creating new databases?
Option 1: Create Roles Once, Grant Privileges Per Database
Option 2: Create a Standardized Setup Script, that you run for each new database
Option 3: Use a Template Database, similar to model in SQL Server
Option 4: Create a function that sets up privileges: call this function in each database
Option 5: Use a Database Extension or Tool that Automates Privilege Management
*/

/******************************
* DEMO SECTION III *
* NOINHERIT IF TIME PERMITS *
*******************************/
CREATE ROLE parent_role NOLOGIN;
CREATE ROLE child_role_inherit NOLOGIN INHERIT; --default behavior
CREATE ROLE child_role_no_inherit NOLOGIN NOINHERIT;

-- Grant parent_role to child_role_inherit
GRANT parent_role TO child_role_inherit;    
-- Grant parent_role to child_role_no_inherit
GRANT parent_role TO child_role_no_inherit;
-- Check the current roles and their inheritance
SELECT rolname, rolinherit  
FROM pg_roles
WHERE rolname IN ('parent_role', 'child_role_inherit', 'child_role_no_inherit');

-- Set a privilege on the parent_role
GRANT SELECT ON ALL TABLES IN SCHEMA public TO parent_role;
-- Test the privileges for each child role
SET ROLE child_role_inherit;
SELECT * FROM test_table;
SET ROLE NONE;

SET ROLE child_role_no_inherit;
SELECT * FROM test_table3;
SET ROLE NONE;


/*
Clean up everything we created so far
Change connection to the postgres database
First, disconnect all connections to the database
Replace 'nyctourdemo' with your database name if different
*/
SELECT pg_terminate_backend(pg_stat_activity.pid)
FROM pg_stat_activity
WHERE datname = 'nyctourdemo';

DROP DATABASE IF EXISTS nyctourdemo;

SELECT pg_terminate_backend(pg_stat_activity.pid)
FROM pg_stat_activity
WHERE datname = 'nyctourdemo2';

DROP DATABASE IF EXISTS nyctourdemo2;



-- Drop all roles we created
-- List all objects that depend on the role 'devlogin' in the 'adventureworks' database
-- This includes owned objects and privileges granted to the role
/*
In case of issues with dropping roles, you can revoke all privileges on the public schema from the role before dropping it.

-- Revoke all privileges on the public schema from devlogin
REVOKE ALL PRIVILEGES ON SCHEMA public FROM devlogin;
-- Revoke all privileges on all tables in public schema from devlogin
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM devlogin;
-- Revoke all privileges on all sequences in public schema from devlogin
REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public FROM devlogin;
-- Revoke all privileges on all functions in public schema from devlogin
REVOKE ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public FROM devlogin;

-- Revoke default privileges owned by devgroup in public schema
ALTER DEFAULT PRIVILEGES FOR ROLE devgroup IN SCHEMA public REVOKE ALL ON TABLES FROM devgroup;
-- Remove any other default privileges if set
ALTER DEFAULT PRIVILEGES FOR ROLE devgroup IN SCHEMA public REVOKE ALL ON SEQUENCES FROM devgroup;
ALTER DEFAULT PRIVILEGES FOR ROLE devgroup IN SCHEMA public REVOKE ALL ON FUNCTIONS FROM devgroup;
ALTER DEFAULT PRIVILEGES FOR ROLE devgroup IN SCHEMA public REVOKE ALL ON TYPES FROM devgroup;
*/
DROP ROLE IF EXISTS parent_role;
DROP ROLE IF EXISTS child_role_inherit;
DROP ROLE IF EXISTS child_role_no_inherit;
DROP ROLE IF EXISTS devlogin;
DROP ROLE IF EXISTS devlogin2;
DROP ROLE IF EXISTS readlogin;
DROP ROLE IF EXISTS readlogin2;
DROP ROLE IF EXISTS readonlygroup;
DROP ROLE IF EXISTS devgroup;