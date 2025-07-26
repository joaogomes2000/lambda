-- public.app_instance_connector definition

-- Drop table

-- DROP TABLE public.app_instance_connector;

CREATE TABLE public.app_instance_connector (
	id bigserial NOT NULL,
	application_id int8 NOT NULL,
	app_instance_id int8 NOT NULL,
	app_connector_id int8 NOT NULL,
	status varchar(15) DEFAULT 'Activate'::character varying NOT NULL,
	created_at timestamptz DEFAULT now() NOT NULL,
	updated_at timestamptz DEFAULT now() NULL,
	CONSTRAINT app_instance_connector_pkey PRIMARY KEY (id)
);
CREATE INDEX idx_app_instance_connector_idx1 ON public.app_instance_connector USING btree (application_id);
CREATE INDEX idx_app_instance_connector_idx2 ON public.app_instance_connector USING btree (app_instance_id);
CREATE INDEX idx_app_instance_connector_idx3 ON public.app_instance_connector USING btree (app_connector_id);
CREATE INDEX idx_app_instance_connector_idx4 ON public.app_instance_connector USING btree (app_instance_id, app_connector_id);

-- create function
CREATE OR REPLACE FUNCTION public.f_aui_application_connector()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  if TG_OP = 'INSERT' and new."name" != 'katalist' then
       -- Insert into fe schema table
       insert into public.app_instance_connector (application_id, app_instance_id, app_connector_id)
       select new.application_id, i.id,  new.id
  		from public.application_instances i
  		where i.application_id = new.application_id;
  elsif TG_OP = 'UPDATE' then

     if new.status != old.status then
       update public.app_instance_connector
          set status = new.status
        where app_connector_id = new.id;
    end if;

  elsif TG_OP = 'DELETE' then
       delete from public.app_instance_connector
        where app_connector_id = old.id;
  end if;
  RETURN NEW;

END;

$function$
;

-- DROP FUNCTION public.f_aui_application_instance();

CREATE OR REPLACE FUNCTION public.f_aui_application_instance()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  if TG_OP = 'INSERT' and new."name" != 'katalist' then
       -- Insert into fe schema table
       insert into public.app_instance_connector (application_id, app_instance_id, app_connector_id)
       select new.application_id, new.id, c.id
  		from public.application_connectors c
  		where c.application_id = new.application_id;
  elsif TG_OP = 'UPDATE' then

     if new.status != old.status then
       update public.app_instance_connector
          set status = new.status
        where app_instance_id = new.id;
    end if;

  elsif TG_OP = 'DELETE' then
       delete from public.app_instance_connector
        where app_instance_id = old.id;
  end if;
  RETURN NEW;

END;

$function$
;


-- create trigger
CREATE TRIGGER trg_aui_application_connector AFTER
INSERT
    OR
DELETE
    OR
UPDATE
    ON
    public.application_connectors FOR EACH ROW EXECUTE FUNCTION f_aui_application_connector();


CREATE TRIGGER trg_aui_application_instance AFTER
INSERT
    OR
DELETE
    OR
UPDATE
    ON
    public.application_instances FOR EACH ROW EXECUTE FUNCTION f_aui_application_instance();

-- public.app_instance_connector foreign keys

ALTER TABLE public.app_instance_connector ADD CONSTRAINT application_connectors_id_fkey FOREIGN KEY (app_connector_id) REFERENCES public.application_connectors(id) ON DELETE CASCADE;
ALTER TABLE public.app_instance_connector ADD CONSTRAINT application_id_fkey FOREIGN KEY (application_id) REFERENCES public.applications(id) ON DELETE CASCADE;
ALTER TABLE public.app_instance_connector ADD CONSTRAINT application_instance_id_fkey FOREIGN KEY (app_instance_id) REFERENCES public.application_instances(id) ON DELETE CASCADE;