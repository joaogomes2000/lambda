-- config_model.data_domain_mapping definition

-- Drop table

-- DROP TABLE config_model.data_domain_mapping;

CREATE TABLE config_model.data_domain_mapping (
	id int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
	app_version_id int4 NULL,
	data_domain_id int4 NULL,
	"name" varchar NOT NULL,
	"mapping" text NOT NULL,
	flow_type_id int4 NULL,
	mapping_type text NULL,
	status varchar(1) DEFAULT 'A'::character varying NOT NULL,
	mark_as_deleted bool DEFAULT false NULL,
	create_user varchar DEFAULT CURRENT_USER NOT NULL,
	creation_date timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	update_user varchar NULL,
	update_date timestamp NULL,
	CONSTRAINT data_domain_mapping_ck CHECK (((status)::text = ANY ((ARRAY['A'::character varying, 'I'::character varying])::text[]))),
	CONSTRAINT data_domain_mapping_pk PRIMARY KEY (id)
);

-- create function

CREATE OR REPLACE FUNCTION config_model.f_biu_data_domain_mapping()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
        IF TG_OP = 'UPDATE' THEN
            IF NEW.update_user IS NULL OR NEW.update_user = '' THEN
                NEW.update_user := current_user;
            END IF;
            NEW.update_date := current_timestamp;

            IF NEW.status != OLD.status THEN
                UPDATE config_model.data_domain_app_versions
                SET status = NEW.status
                WHERE data_domain_mapping_id = OLD.id;
            END IF;
        END IF;

        RETURN NEW;
    END;
    $function$
;


-- Table Triggers

CREATE TRIGGER trg_biu_data_domain_mapping BEFORE
INSERT
    OR
UPDATE
    ON
    config_model.data_domain_mapping FOR EACH ROW EXECUTE FUNCTION config_model.f_biu_data_domain_mapping();


-- config_model.data_domain_mapping foreign keys

ALTER TABLE config_model.data_domain_mapping ADD CONSTRAINT data_domain_mapping_application_versions_fk FOREIGN KEY (app_version_id) REFERENCES config_model.application_versions(id) ON DELETE CASCADE;
ALTER TABLE config_model.data_domain_mapping ADD CONSTRAINT data_domain_mapping_data_domains_fk FOREIGN KEY (data_domain_id) REFERENCES config_model.data_domains(id);
ALTER TABLE config_model.data_domain_mapping ADD CONSTRAINT data_domain_mapping_flow_type_fk FOREIGN KEY (flow_type_id) REFERENCES config_model.flow_type(id) ON DELETE CASCADE;