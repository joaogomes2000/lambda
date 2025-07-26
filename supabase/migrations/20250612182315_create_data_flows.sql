-- Create data_flows table
CREATE TABLE IF NOT EXISTS data_flows (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    entity_id BIGINT REFERENCES entities(id) ON DELETE RESTRICT,
    application_id BIGINT REFERENCES applications(id) ON DELETE RESTRICT,
    application_connector_id BIGINT REFERENCES application_connectors(id) ON DELETE RESTRICT,
    description TEXT,
    persist_data BOOLEAN DEFAULT false,
    status VARCHAR(15) NOT NULL DEFAULT 'Active',
    mark_as_deleted BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_data_flows_entity_id ON data_flows(entity_id);
CREATE INDEX IF NOT EXISTS idx_data_flows_application_id ON data_flows(application_id);
CREATE INDEX IF NOT EXISTS idx_data_flows_application_connector_id ON data_flows(application_connector_id);
ALTER TABLE public.data_flows ADD CONSTRAINT data_flows_ck CHECK (((status)::text = ANY ((ARRAY['Active'::character varying, 'Inactive'::character varying])::text[])));


-- Enable RLS (Row Level Security)
ALTER TABLE data_flows ENABLE ROW LEVEL SECURITY;

-- Create RLS policies (adjust based on your auth system)
CREATE POLICY "Users can view data flows" ON data_flows
    FOR SELECT USING (true);

CREATE POLICY "Users can insert data flows" ON data_flows
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can update data flows" ON data_flows
    FOR UPDATE USING (true);

CREATE POLICY "Users can delete data flows" ON data_flows
    FOR DELETE USING (true);

-- Add trigger for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';
CREATE OR REPLACE FUNCTION public.f_sync_data_flows()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_data_domain_app_versions_id int := 0;
	v_orch_id int := 0;
	v_step_number int := 1;
	v_connection_id int := null;
    v_protocol_type text := '';
BEGIN
  if TG_OP = 'INSERT' then
       -- Insert into fe schema table
       insert into config_model.data_domain_app_versions (app_version_id, data_domain_id, protocol_type_id, flow_type_id)
      	select av.id, new.entity_id, p.id, f.id
 		 from config_model.application_versions av,
		       public.application_connectors ac,
		       config_model.protocol_type p,
		       config_model.flow_type f,
			   config_model.applications a
		where new.application_id = a.reference_id
		   and av.app_id = a.id
		   and ac.id = new.application_connector_id
		   and ac."type"::varchar = p."name"
		   and ac."direction"::varchar = f."name"
		returning id into v_data_domain_app_versions_id;

		insert into config_model.orch_head (reference_id, name, description)
		values (new.id, new.name, new.description)
		returning id into v_orch_id;

		-- ADD Transportation step if protocol_type is FIle and there is an external connection
		select "type" 
		  into v_protocol_type
		  from public.application_connectors 
		  where id = new.application_connector_id;

		if v_protocol_type = 'api' or v_protocol_type = 'db' then

			select c.id  into v_connection_id
			  from config_model.connections c
			       join config_model.application_versions av on av.app_id = c.app_id
				   join config_model.data_domain_app_versions  ddav on ddav.app_version_id = av.id 
			  where ddav.id = v_data_domain_app_versions_id and ddav.protocol_type_id = c.protocol_type_id;
		
		end if;
		

			insert into config_model.orch_steps (orch_id, orch_step, name, data_domain_app_version_id, connection_id)
			  values(v_orch_id, v_step_number, new.name, v_data_domain_app_versions_id, v_connection_id);
		
	--	else
	--		insert into config_model.orch_steps (orch_id, orch_step, name, data_domain_app_version_id)
	--		values(v_orch_id, v_step_number, new.name, v_data_domain_app_versions_id);
	--	end if;

		v_step_number := v_step_number + 1;

		if new.persist_data = true then
			select ddav.id
			  into v_data_domain_app_versions_id
			  from config_model.data_domain_app_versions ddav
			  left join config_model.protocol_type pt on ddav.protocol_type_id = pt.id
			 where data_domain_id = new.entity_id
			   and pt.name = 'sync';

			insert into config_model.orch_steps (orch_id, orch_step, name, data_domain_app_version_id)
			values(v_orch_id, v_step_number, ('Sync ' || new.name), v_data_domain_app_versions_id);
		end if;

		insert into public.data_flow_attrs
		(data_flow_id, attr_id, attr_name, required, protocol_type, flow_type, attr_value, context, be_orch_step_id)
		select new.id, osa.attr_id, a."name" as attr_name, osa.required, pt."name" as protocol_type, ft."name" as flow_type, osa.attr_value as attr_value, a.context, os.id as orch_step_id
		  from config_model.orch_step_attrs osa
		  left join config_model.orch_steps os on os.id = osa.orch_step_id
		  left join config_model.data_domain_app_versions ddav on os.data_domain_app_version_id = ddav.id
		  left join config_model.attributes a on a.id = osa.attr_id
		  left join config_model.protocol_type pt on pt.id = a.protocol_type_id
		  left join config_model.flow_type ft on ft.id = ddav.flow_type_id
		 where orch_id = v_orch_id;

/*
	fazer update e delete
	verificar update que temos de fazer algo parecido que estamos a fazer no insert e validar o persist_data se já existir ou não
	rever insert para saber se vamos ter de criar novas tabelas para criar mais steps ou não e rever os updates e delete
elsif TG_OP = 'UPDATE' then

     if new.status != old.status then
       update config_model.data_domain_app_versions
          set status = new.status
        where app_connector_id = new.id;
    end if;

  elsif TG_OP = 'DELETE' then
       delete from public.app_instance_connector
        where app_connector_id = old.id;*/
  end if;
  RETURN NEW;
END;
$function$
;


CREATE TRIGGER update_data_flows_updated_at
    BEFORE UPDATE ON data_flows
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_sync_data_flows AFTER
INSERT
    OR
DELETE
    OR
UPDATE
    ON
    public.data_flows FOR EACH ROW EXECUTE FUNCTION f_sync_data_flows();