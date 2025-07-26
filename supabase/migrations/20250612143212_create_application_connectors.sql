-- Create enum types
CREATE TYPE connector_type AS ENUM ('db', 'api', 'file');
CREATE TYPE direction AS ENUM ('inbound', 'outbound');

-- Create application_connectors table
CREATE TABLE application_connectors (
  id BIGSERIAL PRIMARY KEY,
  application_id BIGINT NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  type connector_type NOT NULL,
  direction direction NOT NULL,
  config JSONB,
  status VARCHAR(15) NOT NULL DEFAULT 'Active',
  mark_as_deleted BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX idx_application_connectors_application_id ON application_connectors(application_id);
CREATE INDEX idx_application_connectors_type ON application_connectors(type);
CREATE INDEX idx_application_connectors_direction ON application_connectors(direction);
CREATE INDEX idx_application_connectors_config ON application_connectors USING GIN(config);
ALTER TABLE public.application_connectors ADD CONSTRAINT application_connectors_ck CHECK (((status)::text = ANY ((ARRAY['Active'::character varying, 'Inactive'::character varying])::text[])));

-- Enable RLS
ALTER TABLE application_connectors ENABLE ROW LEVEL SECURITY;

-- -- Create RLS policies (adjust according to your auth setup)
-- CREATE POLICY "Enable read access for all users" ON application_connectors FOR SELECT USING (true);
-- CREATE POLICY "Enable insert for authenticated users only" ON application_connectors FOR INSERT WITH CHECK (auth.role() = 'authenticated');
-- CREATE POLICY "Enable update for authenticated users only" ON application_connectors FOR UPDATE USING (auth.role() = 'authenticated');
-- CREATE POLICY "Enable delete for authenticated users only" ON application_connectors FOR DELETE USING (auth.role() = 'authenticated');

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to automatically update updated_at
CREATE TRIGGER update_application_connectors_updated_at
    BEFORE UPDATE ON application_connectors
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Optional: Add validation function for config based on type
CREATE OR REPLACE FUNCTION validate_connector_config()
RETURNS TRIGGER AS $$
BEGIN
  -- Validate DB config
  IF NEW.type = 'db' THEN
    IF NEW.config IS NULL OR
       NOT (NEW.config ? 'host' AND NEW.config ? 'port' AND
            NEW.config ? 'username' AND NEW.config ? 'password' AND
            NEW.config ? 'database') THEN
      RAISE EXCEPTION 'DB connector requires host, port, username, password, and database in config';
    END IF;
  END IF;

  -- Validate API config
  IF NEW.type = 'api' THEN
    IF NEW.config IS NULL OR
       NOT (NEW.config ? 'action' AND NEW.config ? 'url' AND NEW.config ? 'headers') THEN
      RAISE EXCEPTION 'API connector requires action, url, and headers in config';
    END IF;
  END IF;

  -- Validate File config
  IF NEW.type = 'file' THEN
    IF NEW.config IS NULL OR
       NOT (NEW.config ? 'path' AND NEW.config ? 'format') THEN
      RAISE EXCEPTION 'File connector requires path and format in config';
    END IF;
  END IF;

  RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for config validation
CREATE TRIGGER validate_connector_config_trigger
    BEFORE INSERT OR UPDATE ON application_connectors
    FOR EACH ROW EXECUTE FUNCTION validate_connector_config();

-- Insert some sample data for testing (optional - uncomment when you have applications)
-- First, make sure you have at least one application:
-- INSERT INTO applications (name, version, description) VALUES ('Sample App', '1.0.0', 'Sample application for testing');

-- Then you can add connectors:
-- INSERT INTO application_connectors (application_id, name, description, type, direction, config) VALUES
-- ((SELECT id FROM applications LIMIT 1), 'Database Connector', 'PostgreSQL database connection', 'db', 'inbound', '{"host": "localhost", "port": "5432", "username": "user", "password": "pass", "database": "mydb"}'),
-- ((SELECT id FROM applications LIMIT 1), 'API Connector', 'REST API endpoint', 'api', 'outbound', '{"action": "GET", "url": "https://api.example.com/data", "headers": {"Authorization": "Bearer token"}}'),
-- ((SELECT id FROM applications LIMIT 1), 'File Connector', 'CSV file processor', 'file', 'inbound', '{"path": "/data/input.csv", "format": "csv"}');