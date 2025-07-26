-- public.auth_params definition

-- Drop table

-- DROP TABLE public.auth_params;

CREATE TABLE public.auth_params (
	id bigserial NOT NULL,
	"name" varchar NULL,
	"label" varchar NULL,
	description varchar NULL,
	protocol_type varchar NULL,
	auth_type varchar NULL,
	required bool DEFAULT true NOT NULL,
	is_secret bool DEFAULT false NOT NULL,
	"default" varchar NULL,
	visible bool DEFAULT true NOT NULL,
	status varchar DEFAULT 'Active'::character varying NULL,
	created_at timestamptz DEFAULT now() NULL,
	created_by varchar DEFAULT USER NULL,
	updated_at timestamptz DEFAULT now() NULL,
	updated_by varchar DEFAULT USER NULL,
	CONSTRAINT auth_params_pkey PRIMARY KEY (id)
);
CREATE INDEX idx_auth_params_auth_type ON public.auth_params USING btree (auth_type);
CREATE INDEX idx_auth_params_created_at ON public.auth_params USING btree (created_at);
CREATE INDEX idx_auth_params_name ON public.auth_params USING btree (name);
CREATE INDEX idx_auth_params_protocol_type ON public.auth_params USING btree (protocol_type);

-- create function
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

CREATE TRIGGER update_attributes_updated_at BEFORE
UPDATE
    ON
    public.auth_params FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();