-- config_model.application_instance definition

-- Drop table

-- DROP TABLE config_model.application_instance;

CREATE TABLE config_model.application_instance (
	id int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
	app_id int4 NOT NULL,
	"name" varchar NOT NULL,
	description varchar NULL,
	status varchar(1) DEFAULT 'A'::character varying NOT NULL,
	create_user varchar DEFAULT CURRENT_USER NOT NULL,
	creation_date timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	update_user varchar NULL,
	update_date timestamp NULL,
	mark_as_deleted bool DEFAULT false NULL,
	CONSTRAINT application_instance_ck CHECK (((status)::text = ANY ((ARRAY['A'::character varying, 'I'::character varying])::text[]))),
	CONSTRAINT application_instance_pk PRIMARY KEY (id)
);

-- create function
-- DROP FUNCTION config_model.f_biu_application_instance();

CREATE OR REPLACE FUNCTION config_model.f_biu_application_instance()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
        IF TG_OP = 'INSERT' AND NEW.description IS NULL THEN
            NEW.description := NEW.name || ' ' || 'instance';
        END IF;

        IF TG_OP = 'UPDATE' THEN
            NEW.update_user := current_user;
            NEW.update_date := current_timestamp;

            IF NEW.status != OLD.status THEN
                UPDATE config_model.application_instance_attr
                SET status = NEW.status
                WHERE app_instance_id = OLD.id;
            END IF;
        END IF;

        RETURN NEW;
    END;
    $function$
;



-- Table Triggers

CREATE TRIGGER trg_biu_application_instance BEFORE
INSERT
    OR
UPDATE
    ON
    config_model.application_instance FOR EACH ROW EXECUTE FUNCTION config_model.f_biu_application_instance();


-- config_model.application_instance foreign keys

ALTER TABLE config_model.application_instance ADD CONSTRAINT application_instance_app_id_fkey FOREIGN KEY (app_id) REFERENCES config_model.applications(id) ON DELETE CASCADE;