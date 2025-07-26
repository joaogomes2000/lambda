-- config_model.ctrl_orch definition

-- Drop table

-- DROP TABLE config_model.ctrl_orch;

CREATE TABLE config_model.ctrl_orch (
	correlation_manager_id varchar NOT NULL,
	correlation_id varchar NOT NULL,
	orch_id int4 NOT NULL,
	orch_name varchar NOT NULL,
	msg text NULL,
	is_manual bool DEFAULT false NOT NULL,
	status varchar(1) DEFAULT 'Q'::character varying NOT NULL,
	begin_timestamp timestamp NULL,
	end_timestamp timestamp NULL,
	create_user varchar DEFAULT CURRENT_USER NULL,
	creation_date timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	update_user varchar NULL,
	update_date timestamp NULL,
	CONSTRAINT ctrl_orch_ck CHECK (((status)::text = ANY ((ARRAY['R'::character varying, 'Q'::character varying, 'W'::character varying, 'P'::character varying, 'E'::character varying])::text[]))),
	CONSTRAINT ctrl_orch_pk PRIMARY KEY (correlation_id)
);

-- create function

CREATE OR REPLACE FUNCTION config_model.f_bu_generic()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
        IF TG_OP = 'UPDATE' THEN
            IF NEW.update_user IS NULL OR NEW.update_user = '' THEN
                NEW.update_user := current_user;
            END IF;
            IF NEW.update_date IS NULL THEN
                NEW.update_date := CURRENT_TIMESTAMP;
            END IF;
        END IF;

        RETURN NEW;
    END;
    $function$
;

CREATE OR REPLACE FUNCTION config_model.f_sync_ctrl_orch()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_status_id int := 0;
BEGIN
  if TG_OP = 'INSERT' then
		SELECT s.id INTO v_status_id
		FROM public.status s
		WHERE s.description = (
		    CASE NEW.status
		        WHEN 'Q' THEN 'Processing'
		        WHEN 'W' THEN 'Warning'
		        WHEN 'E' THEN 'Error'
		        WHEN 'P' THEN 'Processed'
		        WHEN 'R' THEN 'Recovered'
		        ELSE NULL
		    END
		);

		if v_status_id is not null
			then
				insert into public.monitoring_dataflow
				(dataflow_id, application_id, entity_id, "type", "name", protocol, direction, duration, statusid, execution_flow_id)
				select new.orch_id,
				       a.reference_id,
				       d.data_domain_id,
					   p.name::public.connector_type,
				       new.orch_name AS name,
				       p.name AS protocol,
				       f.description AS direction,
				       (new.end_timestamp - new.begin_timestamp)::interval::text::time AS duration,
				       v_status_id AS statusid,
				       new.correlation_id
				  from config_model.orch_steps os
				  left join config_model.data_domain_app_versions d on os.data_domain_app_version_id = d.id
				  left join config_model.application_versions av on d.app_version_id = av.id
				  left join config_model.protocol_type p on d.protocol_type_id = p.id
				  left join config_model.flow_type f on d.flow_type_id = f.id
				  left join config_model.applications a on a.id = av.app_id
				where os.orch_id = new.orch_id
				   and p."name" in ('file', 'api', 'db');

		end if;


	elsif TG_OP = 'UPDATE' then
     if new.status != old.status then
		SELECT s.id INTO v_status_id
		FROM public.status s
		WHERE s.description = (
		    CASE NEW.status
		        WHEN 'Q' THEN 'Processing'
		        WHEN 'W' THEN 'Warning'
		        WHEN 'E' THEN 'Error'
		        WHEN 'P' THEN 'Processed'
		        WHEN 'R' THEN 'Recovered'
		        ELSE NULL
		    END
		);
       update public.monitoring_dataflow
          set statusid = v_status_id,
			  name = new.name,
			  duration = (new.end_timestamp - new.begin_timestamp)::interval::text::time
        where execution_flow_id = new.correlation_id;
    end if;

  elsif TG_OP = 'DELETE' then
       delete from public.monitoring_dataflow
        where execution_flow_id = new.correlation_id;
  end if;
  RETURN NEW;
END;
$function$
;



-- Table Triggers

CREATE TRIGGER trg_sync_ctrl_orch AFTER
INSERT
    OR
DELETE
    OR
UPDATE
    ON
    config_model.ctrl_orch FOR EACH ROW EXECUTE FUNCTION config_model.f_sync_ctrl_orch();
CREATE TRIGGER trg_bu_ctrl_orch BEFORE
UPDATE
    ON
    config_model.ctrl_orch FOR EACH ROW EXECUTE FUNCTION config_model.f_bu_generic();


-- config_model.ctrl_orch foreign keys

ALTER TABLE config_model.ctrl_orch ADD CONSTRAINT ctrl_orch_correlation_manager_id_fkey FOREIGN KEY (correlation_manager_id) REFERENCES config_model.ctrl_orch_manager(correlation_manager_id) ON DELETE CASCADE;
ALTER TABLE config_model.ctrl_orch ADD CONSTRAINT ctrl_orch_orch_id_fkey FOREIGN KEY (orch_id) REFERENCES config_model.orch_head(id) ON DELETE CASCADE;