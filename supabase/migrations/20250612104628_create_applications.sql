-- Create applications table
CREATE TABLE IF NOT EXISTS applications (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  version VARCHAR(50) NOT NULL,
  status VARCHAR(15) NOT NULL DEFAULT 'Active',
  mark_as_deleted BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_applications_name ON applications(name);
CREATE INDEX IF NOT EXISTS idx_applications_created_at ON applications(created_at);
CREATE INDEX IF NOT EXISTS idx_applications_version ON applications(version);

ALTER TABLE public.applications ADD CONSTRAINT applications_ck CHECK (((status)::text = ANY ((ARRAY['Active'::character varying, 'Inactive'::character varying])::text[])));

-- Create function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- DROP FUNCTION public.f_sync_applications();

CREATE OR REPLACE FUNCTION public.f_sync_applications()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_application_id int := 0;
BEGIN
  if TG_OP = 'INSERT' and new."name" != 'katalist' then
       -- Insert into fe schema table
       insert into config_model.applications (reference_id, name, description)
       values (new.id, new.name, new.description)
		returning id into v_application_id;

       insert into config_model.application_versions (app_id, name, description)
       values (v_application_id, new."version", new.description || ' ' || new."version");
  elsif TG_OP = 'UPDATE' then

     if new."name" != 'katalist' then
       update config_model.applications
          set "name" = new."name",
              description = new.description
              --status = new.status,
        where reference_id = old.id
		returning id into v_application_id;

       update config_model.application_versions
          set "name" = new."version",
              description = new.description  || ' ' || new."version"
        where app_id = v_application_id;

    end if;

  elsif TG_OP = 'DELETE' then
		delete from config_model.applications
		where reference_id = old.id;

  end if;
  RETURN NEW;

END;

$function$
;


-- Create trigger to update updated_at on record updates
CREATE TRIGGER update_applications_updated_at
    BEFORE UPDATE ON applications
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_sync_applications AFTER
INSERT
    OR
DELETE
    OR
UPDATE
    ON
    public.applications FOR EACH ROW EXECUTE FUNCTION f_sync_applications();


