ALTER TABLE monitoring_orchestrations
ADD COLUMN IF NOT EXISTS observations varchar(250) NULL;