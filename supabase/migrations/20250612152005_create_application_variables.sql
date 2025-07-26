-- Create application_variables table
CREATE TABLE IF NOT EXISTS application_variables (
    id BIGSERIAL PRIMARY KEY,
    application_id BIGINT NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    is_secret BOOLEAN NOT NULL DEFAULT FALSE,
    type VARCHAR(50) NOT NULL DEFAULT 'string',
    value TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Ensure unique variable names per application
    UNIQUE(application_id, name)
);

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_application_variables_application_id ON application_variables(application_id);
CREATE INDEX IF NOT EXISTS idx_application_variables_name ON application_variables(name);
CREATE INDEX IF NOT EXISTS idx_application_variables_type ON application_variables(type);
CREATE INDEX IF NOT EXISTS idx_application_variables_is_secret ON application_variables(is_secret);

-- Enable RLS (Row Level Security)
ALTER TABLE application_variables ENABLE ROW LEVEL SECURITY;

-- Create RLS policies (adjust based on your auth system)
CREATE POLICY "Users can view application variables" ON application_variables
    FOR SELECT USING (true);

CREATE POLICY "Users can insert application variables" ON application_variables
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can update application variables" ON application_variables
    FOR UPDATE USING (true);

CREATE POLICY "Users can delete application variables" ON application_variables
    FOR DELETE USING (true);

-- Add trigger for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_application_variables_updated_at
    BEFORE UPDATE ON application_variables
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();