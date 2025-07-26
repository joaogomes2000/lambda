-- Remove cron from orchestration_steps
ALTER TABLE orchestration_steps DROP COLUMN IF EXISTS cron;

-- Add cron to orchestrations
ALTER TABLE orchestrations ADD COLUMN IF NOT EXISTS cron TEXT DEFAULT '* * * * *';
