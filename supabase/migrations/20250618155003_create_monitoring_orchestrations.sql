-- Create monitoring_orchestrations table
CREATE TABLE IF NOT EXISTS monitoring_orchestrations (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  start_time TIMESTAMPTZ NOT NULL,
  duration INTERVAL NOT NULL,
  flow_number INTEGER NOT NULL,
  statusId   INT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT fk_status_monitoring_orchestrations
    FOREIGN KEY (statusId)
    REFERENCES status(id)

  
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_monitoring_orchestrations_start_time ON monitoring_orchestrations(start_time);

-- Trigger to update updated_at on record updates
CREATE TRIGGER update_monitoring_orchestrations_updated_at
    BEFORE UPDATE ON monitoring_orchestrations
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();