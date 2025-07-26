CREATE TABLE IF NOT EXISTS orchestrations (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  status VARCHAR(15) DEFAULT 'Activate',
  mark_as_deleted BOOLEAN DEFAULT false,
  last_exec_status TEXT,
  last_exec_date TIMESTAMPTZ DEFAULT NOW(),
  last_exec_duration TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_orchestrations_name ON public.orchestrations(name);
CREATE INDEX IF NOT EXISTS idx_orchestrations_created_at ON public.orchestrations(created_at);

-- Create function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to update updated_at on record updates
CREATE TRIGGER update_orchestrations_updated_at
    BEFORE UPDATE ON public.orchestrations
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();