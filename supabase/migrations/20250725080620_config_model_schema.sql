-- OPTIONAL: Create the schema if it does not exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.schemata WHERE schema_name = 'config_model'
    ) THEN
        CREATE SCHEMA config_model;
    END IF;
END
$$;

grant select, insert, update, delete on all tables in schema config_model to authenticated;
grant select, insert, update, delete on all tables in schema config_model to anon;
alter default privileges in schema config_model grant select, insert, update, delete on tables to authenticated;
alter default privileges in schema config_model grant select, insert, update, delete on tables to anon;

