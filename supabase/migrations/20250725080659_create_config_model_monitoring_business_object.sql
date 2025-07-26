-- config_model.monitoring_business_object definition

-- Drop table

-- DROP TABLE config_model.monitoring_business_object;

CREATE TABLE config_model.monitoring_business_object (
	correlation_id varchar NOT NULL,
	orch_id int4 NOT NULL,
	orch_step_id int4 NOT NULL,
	app_version_id int4 NOT NULL,
	app_instance_id int4 NULL,
	flow_type_id int4 NOT NULL,
	data_domain_id int4 NOT NULL,
	protocol_type_id int4 NOT NULL,
	business_object_id int4 NOT NULL,
	business_object_values varchar NOT NULL,
	"action" varchar(10) NULL,
	create_user varchar DEFAULT CURRENT_USER NOT NULL,
	creation_date timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	update_user varchar NULL,
	update_date timestamp NULL,
	CONSTRAINT monitoring_business_object_ck1 CHECK (((action)::text = ANY ((ARRAY['CREATE'::character varying, 'UPDATE'::character varying, 'DELETE'::character varying])::text[]))),
	CONSTRAINT monitoring_business_object_pkey PRIMARY KEY (correlation_id, business_object_id, business_object_values)
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


-- Table Triggers

CREATE TRIGGER trg_bu_monitoring_business_object BEFORE
UPDATE
    ON
    config_model.monitoring_business_object FOR EACH ROW EXECUTE FUNCTION config_model.f_bu_generic();


-- config_model.monitoring_business_object foreign keys

ALTER TABLE config_model.monitoring_business_object ADD CONSTRAINT app_instance_id_fkey FOREIGN KEY (app_instance_id) REFERENCES config_model.application_instance(id) ON DELETE CASCADE;
ALTER TABLE config_model.monitoring_business_object ADD CONSTRAINT app_version_id_fkey FOREIGN KEY (app_version_id) REFERENCES config_model.application_versions(id) ON DELETE CASCADE;
ALTER TABLE config_model.monitoring_business_object ADD CONSTRAINT business_object_id_fkey FOREIGN KEY (business_object_id) REFERENCES config_model.business_object(id) ON DELETE CASCADE;
ALTER TABLE config_model.monitoring_business_object ADD CONSTRAINT correlation_id_fkey FOREIGN KEY (correlation_id) REFERENCES config_model.ctrl_orch(correlation_id) ON DELETE CASCADE;
ALTER TABLE config_model.monitoring_business_object ADD CONSTRAINT data_domain_id_fkey FOREIGN KEY (data_domain_id) REFERENCES config_model.data_domains(id) ON DELETE CASCADE;
ALTER TABLE config_model.monitoring_business_object ADD CONSTRAINT flow_type_id_fkey FOREIGN KEY (flow_type_id) REFERENCES config_model.flow_type(id) ON DELETE CASCADE;
ALTER TABLE config_model.monitoring_business_object ADD CONSTRAINT orch_id_fkey FOREIGN KEY (orch_id) REFERENCES config_model.orch_head(id) ON DELETE CASCADE;
ALTER TABLE config_model.monitoring_business_object ADD CONSTRAINT orch_step_id_fkey FOREIGN KEY (orch_step_id) REFERENCES config_model.orch_steps(id) ON DELETE CASCADE;
ALTER TABLE config_model.monitoring_business_object ADD CONSTRAINT protocol_type_id_fkey FOREIGN KEY (protocol_type_id) REFERENCES config_model.protocol_type(id) ON DELETE CASCADE;