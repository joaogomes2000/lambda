-- OPTIONAL: Create the schema if it does not exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.schemata WHERE schema_name = 'core'
    ) THEN
        CREATE SCHEMA core;
    END IF;
END
$$;

-- Step 1: Create the read-only user with a secure password
-- Replace with a secure password of your choice
CREATE USER core_read_only WITH PASSWORD 'postgres';

-- Step 2: Grant USAGE on the schema so the user can access it
GRANT USAGE ON SCHEMA core TO core_read_only;

-- Step 3: Grant SELECT on all existing tables in the schema
GRANT SELECT ON ALL TABLES IN SCHEMA core TO core_read_only;

-- Optional: Also grant SELECT on sequences, views, etc., if applicable
GRANT SELECT ON ALL SEQUENCES IN SCHEMA core TO core_read_only;


-- Step 4: Set default privileges for future tables created by current user
ALTER DEFAULT PRIVILEGES IN SCHEMA core GRANT SELECT ON TABLES TO core_read_only;

-- Step 5: Set default search_path for the user
ALTER ROLE core_read_only SET search_path = core;
