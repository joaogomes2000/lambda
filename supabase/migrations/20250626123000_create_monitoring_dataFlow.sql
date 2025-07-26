-- Create monitoring_dataFlow table
CREATE TABLE IF NOT EXISTS monitoring_dataFlow (
  id BIGSERIAL PRIMARY KEY,
  dataflow_id BIGINT NOT NULL REFERENCES data_flows(id),
  application_id BIGINT REFERENCES applications(id),
  entity_id BIGINT REFERENCES entities(id),
  type connector_type NOT NULL,
  name VARCHAR(255) NOT NULL,
  protocol VARCHAR(50) NOT NULL,
  direction VARCHAR(50) NOT NULL,
  duration TIME NOT NULL,
  statusId   INT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT fk_status_monitoring_dataFlow
    FOREIGN KEY (statusId)
    REFERENCES status(id)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_monitoring_dataFlow_application_id ON monitoring_dataFlow(application_id);

-- Trigger to update updated_at on record updates
CREATE TRIGGER update_monitoring_dataFlow_updated_at
    BEFORE UPDATE ON monitoring_dataFlow
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();