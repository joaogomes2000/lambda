-- Create application_instances table
CREATE TABLE IF NOT EXISTS application_instances (
  id BIGSERIAL PRIMARY KEY,
  application_id BIGINT REFERENCES applications(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  status VARCHAR(15) NOT NULL DEFAULT 'Active',
  mark_as_deleted BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_application_instances_application_id ON application_instances(application_id);
CREATE INDEX IF NOT EXISTS idx_application_instances_name ON application_instances(name);
CREATE INDEX IF NOT EXISTS idx_application_instances_created_at ON application_instances(created_at);
ALTER TABLE public.application_instances ADD CONSTRAINT application_instances_ck CHECK (((status)::text = ANY ((ARRAY['Active'::character varying, 'Inactive'::character varying])::text[])));

-- Create trigger to update updated_at on record updates
CREATE TRIGGER update_application_instances_updated_at
    BEFORE UPDATE ON application_instances
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();