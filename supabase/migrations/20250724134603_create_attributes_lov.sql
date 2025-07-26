-- public.attributes_lov definition

-- Drop table

-- DROP TABLE public.attributes_lov;

CREATE TABLE public.attributes_lov (
	id bigserial NOT NULL,
	attr_lov_id int4 NOT NULL,
	value varchar NULL,
	"label" varchar NULL,
	status varchar DEFAULT 'Active'::character varying NULL,
	created_at timestamptz DEFAULT now() NULL,
	created_by varchar DEFAULT USER NULL,
	updated_at timestamptz DEFAULT now() NULL,
	updated_by varchar DEFAULT USER NULL,
	CONSTRAINT attributes_lov_pkey PRIMARY KEY (id)
);

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
    public.attributes_lov FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();