ALTER TABLE monitoring_dataFlow
ADD COLUMN IF NOT EXISTS execution_flow_id varchar(50),
ADD COLUMN IF NOT EXISTS execution_orchestration_id varchar(50);


ALTER TABLE monitoring_dataFlow
ADD CONSTRAINT unique_execution_flow_id UNIQUE (execution_flow_id);

ALTER TABLE monitoring_dataFlow
ADD CONSTRAINT fk_execution_orchestration_id
FOREIGN KEY (execution_orchestration_id)
REFERENCES monitoring_orchestrations(execution_orchestration_id)
ON DELETE SET NULL;
