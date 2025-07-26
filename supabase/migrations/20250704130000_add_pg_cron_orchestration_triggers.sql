-- migration: 20250704130000_add_pg_cron_orchestration_triggers.sql

-- Enable pg_cron extension if not already enabled
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Grant permissions on cron schema to necessary roles
DO $$
BEGIN
    -- Grant permissions to current user
    EXECUTE format('GRANT USAGE ON SCHEMA cron TO %I', current_user);
    EXECUTE format('GRANT ALL ON ALL TABLES IN SCHEMA cron TO %I', current_user);
    EXECUTE format('GRANT ALL ON ALL FUNCTIONS IN SCHEMA cron TO %I', current_user);

    -- Grant permissions to postgres user (common in local development)
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'postgres') THEN
        GRANT USAGE ON SCHEMA cron TO postgres;
        GRANT ALL ON ALL TABLES IN SCHEMA cron TO postgres;
        GRANT ALL ON ALL FUNCTIONS IN SCHEMA cron TO postgres;
        GRANT ALL ON ALL SEQUENCES IN SCHEMA cron TO postgres;
    END IF;

    -- Grant permissions to authenticated role (Supabase)
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
        GRANT USAGE ON SCHEMA cron TO authenticated;
        GRANT ALL ON ALL TABLES IN SCHEMA cron TO authenticated;
        GRANT ALL ON ALL FUNCTIONS IN SCHEMA cron TO authenticated;
        GRANT ALL ON ALL SEQUENCES IN SCHEMA cron TO authenticated;
    END IF;

    -- Grant permissions to service_role (Supabase)
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'service_role') THEN
        GRANT USAGE ON SCHEMA cron TO service_role;
        GRANT ALL ON ALL TABLES IN SCHEMA cron TO service_role;
        GRANT ALL ON ALL FUNCTIONS IN SCHEMA cron TO service_role;
        GRANT ALL ON ALL SEQUENCES IN SCHEMA cron TO service_role;
    END IF;

    -- Grant permissions to anon role (Supabase)
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
        GRANT USAGE ON SCHEMA cron TO anon;
        GRANT ALL ON ALL TABLES IN SCHEMA cron TO anon;
        GRANT ALL ON ALL FUNCTIONS IN SCHEMA cron TO anon;
        GRANT ALL ON ALL SEQUENCES IN SCHEMA cron TO anon;
    END IF;

    -- Grant permissions on net schema for HTTP requests
    IF EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'net') THEN
        GRANT USAGE ON SCHEMA net TO postgres;
        GRANT ALL ON ALL TABLES IN SCHEMA net TO postgres;
        GRANT ALL ON ALL FUNCTIONS IN SCHEMA net TO postgres;

        GRANT USAGE ON SCHEMA net TO authenticated;
        GRANT ALL ON ALL TABLES IN SCHEMA net TO authenticated;
        GRANT ALL ON ALL FUNCTIONS IN SCHEMA net TO authenticated;

        GRANT USAGE ON SCHEMA net TO service_role;
        GRANT ALL ON ALL TABLES IN SCHEMA net TO service_role;
        GRANT ALL ON ALL FUNCTIONS IN SCHEMA net TO service_role;
    END IF;
END $$;

-- Disable RLS on cron.job table for local development
-- This allows all users to manage cron jobs regardless of who created them
DO $$
BEGIN
    -- Try to disable RLS if we have permissions
    IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'job' AND schemaname = 'cron') THEN
        BEGIN
            ALTER TABLE cron.job DISABLE ROW LEVEL SECURITY;
            RAISE NOTICE 'RLS disabled on cron.job table';
        EXCEPTION
            WHEN insufficient_privilege THEN
                RAISE NOTICE 'Cannot disable RLS on cron.job - insufficient privileges';
            WHEN OTHERS THEN
                RAISE NOTICE 'Error disabling RLS on cron.job: %', SQLERRM;
        END;
    END IF;
END $$;

-- Alternative approach: Create a more permissive policy instead
DO $$
BEGIN
    -- Drop existing restrictive policy if it exists
    BEGIN
        DROP POLICY IF EXISTS "cron_job_policy" ON cron.job;
        RAISE NOTICE 'Dropped existing cron_job_policy';
    EXCEPTION
        WHEN insufficient_privilege THEN
            RAISE NOTICE 'Cannot drop cron_job_policy - insufficient privileges';
        WHEN OTHERS THEN
            RAISE NOTICE 'Error dropping cron_job_policy: %', SQLERRM;
    END;

    -- Create a more permissive policy for local development
    BEGIN
        CREATE POLICY "cron_job_policy_permissive" ON cron.job
            USING (username IN ('postgres', 'service_role', 'authenticated') OR username = CURRENT_USER);
        RAISE NOTICE 'Created permissive cron_job_policy';
    EXCEPTION
        WHEN insufficient_privilege THEN
            RAISE NOTICE 'Cannot create cron_job_policy - insufficient privileges';
        WHEN duplicate_object THEN
            RAISE NOTICE 'Permissive cron_job_policy already exists';
        WHEN OTHERS THEN
            RAISE NOTICE 'Error creating cron_job_policy: %', SQLERRM;
    END;
END $$;

-- Function to schedule/unschedule orchestrations in pg_cron
CREATE OR REPLACE FUNCTION manage_orchestration_cron()
RETURNS TRIGGER AS $$
DECLARE
    job_name TEXT;
    cron_schedule TEXT;
    function_url TEXT;
    job_exists BOOLEAN;
    service_key TEXT;
BEGIN
    -- Generate unique job name
    job_name := 'orchestration_' || COALESCE(NEW.id, OLD.id);

    -- Get the cron schedule from the orchestration
    cron_schedule := COALESCE(NEW.cron, OLD.cron, '* * * * *');

    -- Build the function URL - use host.docker.internal (works with net.http_post)
    function_url := 'http://host.docker.internal:8080/api/functions/v1/run-orchestration';

    -- Use the service key directly (Supabase local development key)
    -- This key is ok for non-production environments, we are still wokring on this feature, just doing this for demo purposes
    service_key := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU';

    -- Check if job exists in cron.job table
    SELECT EXISTS(SELECT 1 FROM cron.job WHERE jobname = job_name) INTO job_exists;

    -- Handle INSERT or UPDATE to active status
    IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') AND NEW.status = 'Activate' THEN
        -- Remove existing job if it exists
        IF job_exists THEN
            PERFORM cron.unschedule(job_name);
        END IF;

        -- Schedule new cron job with formatted command (same as working manual command)
        PERFORM cron.schedule(
            job_name,
            cron_schedule,
            'select' || chr(10) ||
            '  net.http_post(' || chr(10) ||
            '      url:=''' || function_url || ''',' || chr(10) ||
            '      headers:=jsonb_build_object(''Authorization'', ''Bearer ' || service_key || '''),' || chr(10) ||
            '      body:=''{"orchestrationId": ' || NEW.id || '}'',' || chr(10) ||
            '      timeout_milliseconds:=5000' || chr(10) ||
            '  );'
        );

        RAISE NOTICE 'Scheduled orchestration % with cron % at %', NEW.id, cron_schedule, function_url;

    -- Handle UPDATE to inactive status or DELETE
    ELSIF (TG_OP = 'UPDATE' AND NEW.status = 'Inactive') OR TG_OP = 'DELETE' THEN
        -- Remove the cron job only if it exists
        IF job_exists THEN
            PERFORM cron.unschedule(job_name);
            RAISE NOTICE 'Unscheduled orchestration %', COALESCE(NEW.id, OLD.id);
        ELSE
            RAISE NOTICE 'Job orchestration_% not found, skipping unschedule', COALESCE(NEW.id, OLD.id);
        END IF;
    END IF;

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for orchestrations table
CREATE TRIGGER orchestration_cron_trigger
    AFTER INSERT OR UPDATE OR DELETE ON orchestrations
    FOR EACH ROW
    EXECUTE FUNCTION manage_orchestration_cron();

-- Enable http extension for making HTTP requests
CREATE EXTENSION IF NOT EXISTS http;

-- Schedule existing active orchestrations
DO $$
DECLARE
    orch RECORD;
    job_name TEXT;
    function_url TEXT;
    service_key TEXT;
BEGIN
    function_url := 'http://host.docker.internal:8080/api/functions/v1/run-orchestration';

    service_key := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU';

    FOR orch IN SELECT * FROM orchestrations WHERE status = 'Activate' LOOP
        job_name := 'orchestration_' || orch.id;

        PERFORM cron.schedule(
            job_name,
            COALESCE(orch.cron, '* * * * *'),
            'select' || chr(10) ||
            '  net.http_post(' || chr(10) ||
            '      url:=''' || function_url || ''',' || chr(10) ||
            '      headers:=jsonb_build_object(''Authorization'', ''Bearer ' || service_key || '''),' || chr(10) ||
            '      body:=''{"orchestrationId": ' || orch.id || '}'',' || chr(10) ||
            '      timeout_milliseconds:=5000' || chr(10) ||
            '  );'
        );

        RAISE NOTICE 'Scheduled existing orchestration % with cron %', orch.id, COALESCE(orch.cron, '* * * * *');
    END LOOP;
END $$;
