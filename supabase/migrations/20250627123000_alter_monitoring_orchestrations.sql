ALTER TABLE monitoring_orchestrations
ADD COLUMN IF NOT EXISTS execution_orchestration_id varchar(50) NULL;

ALTER TABLE monitoring_orchestrations
ADD CONSTRAINT unique_execution_orchestration_id UNIQUE (execution_orchestration_id);