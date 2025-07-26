-- public.data_flow_attrs definition

-- Drop table

-- DROP TABLE public.data_flow_attrs;

CREATE TABLE public.data_flow_attrs (
	id bigserial NOT NULL,
	data_flow_id int4 NOT NULL,
	attr_id int4 NOT NULL,
	attr_name varchar NULL,
	required bool NOT NULL,
	protocol_type varchar NULL,
	flow_type varchar NULL,
	attr_value varchar NULL,
	context varchar(50) NOT NULL,
	be_orch_step_id int4 NOT NULL,
	created_at timestamptz DEFAULT now() NULL,
	created_by varchar DEFAULT USER NULL,
	updated_at timestamptz DEFAULT now() NULL,
	updated_by varchar DEFAULT USER NULL,
	CONSTRAINT data_flow_attrs_pkey PRIMARY KEY (id)
);
CREATE INDEX idx_data_flow_attrs_context ON public.data_flow_attrs USING btree (context);
CREATE INDEX idx_data_flow_attrs_created_at ON public.data_flow_attrs USING btree (created_at);
CREATE INDEX idx_data_flow_attrs_df_id ON public.data_flow_attrs USING btree (data_flow_id);

-- create function

CREATE OR REPLACE FUNCTION public.f_sync_orch_step_attrs()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN

    IF TG_OP = 'UPDATE' THEN
        -- Generate slug from domain_name if slug is null or empty
         update config_model.orch_step_attrs
		 set attr_value = new.attr_value
		 where orch_step_id = new.be_orch_step_id and attr_id = new.attr_id;

    END IF;

    RETURN NEW;
END;
$function$
;

-- DROP FUNCTION public.update_updated_at_column();

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$function$
;


-- Table Triggers

CREATE TRIGGER trg_sync_orch_step_attrs AFTER
UPDATE
    ON
    public.data_flow_attrs FOR EACH ROW EXECUTE FUNCTION f_sync_orch_step_attrs();
CREATE TRIGGER update_data_flow_attrs_updated_at BEFORE
UPDATE
    ON
    public.data_flow_attrs FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();