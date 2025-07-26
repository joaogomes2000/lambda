-- Create entities table
CREATE TABLE IF NOT EXISTS entities (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255),
    description TEXT,
    status VARCHAR(15) NOT NULL DEFAULT 'Active',
    mark_as_deleted BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Ensure unique entity names
    UNIQUE(name)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_entities_name ON entities(name);
ALTER TABLE public.entities ADD CONSTRAINT entities_ck CHECK (((status)::text = ANY ((ARRAY['Active'::character varying, 'Inactive'::character varying])::text[])));

-- Enable RLS (Row Level Security)
ALTER TABLE entities ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view entities" ON entities
    FOR SELECT USING (true);

CREATE POLICY "Users can insert entities" ON entities
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can update entities" ON entities
    FOR UPDATE USING (true);

CREATE POLICY "Users can delete entities" ON entities
    FOR DELETE USING (true);

-- Add trigger for updated_at
CREATE TRIGGER update_entities_updated_at
    BEFORE UPDATE ON entities
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();