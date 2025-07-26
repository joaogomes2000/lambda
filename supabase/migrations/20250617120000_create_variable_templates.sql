-- Create owner_type enum for variable templates
CREATE TYPE owner_type AS ENUM ('application', 'instance', 'connector');

-- Create variable_templates table
CREATE TABLE IF NOT EXISTS variable_templates (
    id BIGSERIAL PRIMARY KEY,
    owner_type owner_type NOT NULL,
    owner_id BIGINT NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    is_secret BOOLEAN NOT NULL DEFAULT FALSE,
    type VARCHAR(50) NOT NULL DEFAULT 'string',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Ensure unique variable names per owner
    UNIQUE(owner_type, owner_id, name)
);

-- Create variables table for actual values
CREATE TABLE IF NOT EXISTS variables (
    id BIGSERIAL PRIMARY KEY,
    template_id BIGINT NOT NULL REFERENCES variable_templates(id) ON DELETE CASCADE,
    owner_type owner_type NOT NULL,
    owner_id BIGINT NOT NULL,
    value TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Ensure unique template per owner
    UNIQUE(template_id, owner_type, owner_id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_variable_templates_owner ON variable_templates(owner_type, owner_id);
CREATE INDEX IF NOT EXISTS idx_variable_templates_name ON variable_templates(name);
CREATE INDEX IF NOT EXISTS idx_variable_templates_type ON variable_templates(type);
CREATE INDEX IF NOT EXISTS idx_variable_templates_is_secret ON variable_templates(is_secret);

CREATE INDEX IF NOT EXISTS idx_variables_template_id ON variables(template_id);
CREATE INDEX IF NOT EXISTS idx_variables_owner ON variables(owner_type, owner_id);

-- Enable RLS (Row Level Security)
ALTER TABLE variable_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE variables ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for variable_templates
CREATE POLICY "Users can view variable templates" ON variable_templates
    FOR SELECT USING (true);

CREATE POLICY "Users can insert variable templates" ON variable_templates
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can update variable templates" ON variable_templates
    FOR UPDATE USING (true);

CREATE POLICY "Users can delete variable templates" ON variable_templates
    FOR DELETE USING (true);

-- Create RLS policies for variables
CREATE POLICY "Users can view variables" ON variables
    FOR SELECT USING (true);

CREATE POLICY "Users can insert variables" ON variables
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can update variables" ON variables
    FOR UPDATE USING (true);

CREATE POLICY "Users can delete variables" ON variables
    FOR DELETE USING (true);

-- Add trigger for updated_at on variable_templates
CREATE TRIGGER update_variable_templates_updated_at
    BEFORE UPDATE ON variable_templates
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Add trigger for updated_at on variables
CREATE TRIGGER update_variables_updated_at
    BEFORE UPDATE ON variables
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Add validation trigger for owner references
CREATE OR REPLACE FUNCTION validate_variable_template_owner()
RETURNS TRIGGER AS $$
BEGIN
    -- Validate that the owner exists based on owner_type
    IF NEW.owner_type = 'application' THEN
        IF NOT EXISTS (SELECT 1 FROM applications WHERE id = NEW.owner_id) THEN
            RAISE EXCEPTION 'Application with id % does not exist', NEW.owner_id;
        END IF;
    ELSIF NEW.owner_type = 'instance' THEN
        IF NOT EXISTS (SELECT 1 FROM application_instances WHERE id = NEW.owner_id) THEN
            RAISE EXCEPTION 'Application instance with id % does not exist', NEW.owner_id;
        END IF;
    ELSIF NEW.owner_type = 'connector' THEN
        IF NOT EXISTS (SELECT 1 FROM application_connectors WHERE id = NEW.owner_id) THEN
            RAISE EXCEPTION 'Application connector with id % does not exist', NEW.owner_id;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER validate_variable_template_owner_trigger
    BEFORE INSERT OR UPDATE ON variable_templates
    FOR EACH ROW
    EXECUTE FUNCTION validate_variable_template_owner();

-- Add validation trigger for variable owner references
CREATE OR REPLACE FUNCTION validate_variable_owner()
RETURNS TRIGGER AS $$
BEGIN
    -- Validate that the owner exists based on owner_type
    IF NEW.owner_type = 'application' THEN
        IF NOT EXISTS (SELECT 1 FROM applications WHERE id = NEW.owner_id) THEN
            RAISE EXCEPTION 'Application with id % does not exist', NEW.owner_id;
        END IF;
    ELSIF NEW.owner_type = 'instance' THEN
        IF NOT EXISTS (SELECT 1 FROM application_instances WHERE id = NEW.owner_id) THEN
            RAISE EXCEPTION 'Application instance with id % does not exist', NEW.owner_id;
        END IF;
    ELSIF NEW.owner_type = 'connector' THEN
        IF NOT EXISTS (SELECT 1 FROM application_connectors WHERE id = NEW.owner_id) THEN
            RAISE EXCEPTION 'Application connector with id % does not exist', NEW.owner_id;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER validate_variable_owner_trigger
    BEFORE INSERT OR UPDATE ON variables
    FOR EACH ROW
    EXECUTE FUNCTION validate_variable_owner();
