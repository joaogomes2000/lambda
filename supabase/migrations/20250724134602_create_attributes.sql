-- public."attributes" definition

-- Drop table

-- DROP TABLE public."attributes";

CREATE TABLE public."attributes" (
	id bigserial NOT NULL,
	attr_name varchar NULL,
	"label" varchar NULL,
	description varchar NULL,
	protocol_type varchar NULL,
	flow_type varchar NULL,
	context varchar(50) NOT NULL,
	attr_lov_id int4 NULL,
	required bool NOT NULL,
	visible bool DEFAULT true NOT NULL,
	status varchar DEFAULT 'Active'::character varying NULL,
	created_at timestamptz DEFAULT now() NULL,
	created_by varchar DEFAULT USER NULL,
	updated_at timestamptz DEFAULT now() NULL,
	updated_by varchar DEFAULT USER NULL,
	CONSTRAINT attributes_pkey PRIMARY KEY (id)
);
CREATE INDEX idx_attributes_context ON public.attributes USING btree (context);
CREATE INDEX idx_attributes_created_at ON public.attributes USING btree (created_at);
CREATE INDEX idx_attributes_protocol_type ON public.attributes USING btree (protocol_type);

-- create function

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

CREATE TRIGGER update_attributes_updated_at BEFORE
UPDATE
    ON
    public.attributes FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();