-- migration: 20250626131000_create_orchestration_steps.sql

create table if not exists orchestration_steps (
  id serial primary key,
  orchestration_id integer references orchestrations(id) on delete cascade,
  data_flow_id integer references data_flows(id) on delete cascade,
  instance_ids integer[] not null,
  cron varchar(255),
  mark_as_deleted BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ default now(),
  updated_at TIMESTAMPTZ default now()
);

-- Index to search orchestration steps by orchestration_id
create index if not exists idx_orchestration_steps_orchestration_id on orchestration_steps(orchestration_id);
-- Index to search orchestration steps by data_flow_id
create index if not exists idx_orchestration_steps_data_flow_id on orchestration_steps(data_flow_id);
-- Index to search orchestration steps by created_at
create index if not exists idx_orchestration_steps_created_at on orchestration_steps(created_at);


-- Create function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to update updated_at on record updates
CREATE TRIGGER update_orchestration_steps_updated_at
    BEFORE UPDATE ON public.orchestration_steps
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();