-- migration: 20250704120000_add_cron_to_orchestrations.sql

-- Add cron field to orchestrations table
ALTER TABLE orchestrations ADD COLUMN IF NOT EXISTS cron VARCHAR(255);

-- Create index for cron field
CREATE INDEX IF NOT EXISTS idx_orchestrations_cron ON orchestrations(cron);
