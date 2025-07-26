-- Create application_instances table
CREATE TABLE IF NOT EXISTS status (
  id INT       PRIMARY KEY,
  description  TEXT  NOT NULL,
  position         INTEGER NOT NULL,
  isIncrement  BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()

);


-- Create function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_status_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';


-- Trigger to update updated_at on record updates
CREATE TRIGGER trg_update_status_updated_at
    BEFORE UPDATE ON status
    FOR EACH ROW
    EXECUTE FUNCTION update_status_updated_at_column();