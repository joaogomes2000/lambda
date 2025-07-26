CREATE TABLE IF NOT EXISTS monitoring_dataflow_api (
  id               BIGSERIAL PRIMARY KEY,
  action_type      VARCHAR(15) NOT NULL,
  api_url          VARCHAR(50) NOT NULL,
  number_records   INTEGER NOT NULL,
 row_discarded  INTEGER NOT NULL DEFAULT 0,
  row_error      INTEGER NOT NULL DEFAULT 0,
  row_processed  INTEGER NOT NULL  DEFAULT 0,
  statusId         INT NOT NULL,
  dataflow_id      BIGINT NOT NULL,
  created_at       TIMESTAMPTZ DEFAULT NOW(),
  updated_at       TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT fk_dataflow_monitoring_dataflow_api
    FOREIGN KEY (dataflow_id)
    REFERENCES monitoring_dataflow(id)
    ON DELETE CASCADE,

  CONSTRAINT fk_status_monitoring_dataflow_api
    FOREIGN KEY (statusId)
    REFERENCES status(id)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_monitoring_dataflow_api_dataflow_id ON monitoring_dataflow_api(dataflow_id);


-- Trigger to update updated_at
CREATE OR REPLACE FUNCTION update_monitoring_dataflow_api_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER trg_monitoring_dataflow_api_updated_at
  BEFORE UPDATE ON monitoring_dataflow_api
  FOR EACH ROW
  EXECUTE FUNCTION update_monitoring_dataflow_api_updated_at();