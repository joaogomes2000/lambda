-- config_model.business_object definition

-- Drop table

-- DROP TABLE config_model.business_object;

CREATE TABLE config_model.business_object (
	id int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
	data_domain_id int4 NOT NULL,
	app_version_id int4 NULL,
	product_definition bool DEFAULT false NULL,
	create_user varchar DEFAULT CURRENT_USER NULL,
	creation_date timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	update_user varchar NULL,
	update_date timestamp NULL,
	CONSTRAINT business_object_id_pkey PRIMARY KEY (id)
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

CREATE TRIGGER trg_bu_business_object BEFORE
UPDATE
    ON
    config_model.business_object FOR EACH ROW EXECUTE FUNCTION config_model.f_bu_generic();


-- config_model.business_object foreign keys

ALTER TABLE config_model.business_object ADD CONSTRAINT app_version_id_fkey FOREIGN KEY (app_version_id) REFERENCES config_model.application_versions(id) ON DELETE CASCADE;
ALTER TABLE config_model.business_object ADD CONSTRAINT entity_id_fkey FOREIGN KEY (data_domain_id) REFERENCES config_model.data_domains(id) ON DELETE CASCADE;