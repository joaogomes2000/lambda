-- config_model.applications definition

-- Drop table

-- DROP TABLE config_model.applications;

CREATE TABLE config_model.applications (
	id int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
	"name" varchar NOT NULL,
	description varchar NULL,
	product_definition bool DEFAULT false NULL,
	status varchar(1) DEFAULT 'A'::character varying NOT NULL,
	reference_id int4 NULL,
	mark_as_deleted bool DEFAULT false NULL,
	create_user varchar DEFAULT CURRENT_USER NOT NULL,
	creation_date timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	update_user varchar NULL,
	update_date timestamp NULL,
	CONSTRAINT applications_ck CHECK (((status)::text = ANY ((ARRAY['A'::character varying, 'I'::character varying])::text[]))),
	CONSTRAINT applications_pk PRIMARY KEY (id)
);

-- create function

CREATE OR REPLACE FUNCTION config_model.f_bu_applications()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    DECLARE
        l_app_name TEXT := '';
        l_app INT := 0;
    BEGIN
        IF TG_OP = 'INSERT' THEN
            SELECT name
            INTO l_app_name
            FROM config_model.applications
            WHERE name = NEW.name;

            /*IF l_app_name IS NOT NULL THEN
                RAISE EXCEPTION 'application already exists';
            END IF;*/
        END IF;

        IF TG_OP = 'UPDATE' THEN
            IF NEW.update_user IS NULL OR NEW.update_user = '' THEN
                NEW.update_user := current_user;
            END IF;
            NEW.update_date := CURRENT_TIMESTAMP;

            SELECT COUNT(1)
            INTO l_app
            FROM config_model.application_versions
            WHERE app_id = OLD.id;

            IF l_app > 0 THEN
                IF NEW.description != OLD.description AND (NEW.description IS NOT NULL AND NEW.description != '') THEN
                    UPDATE config_model.application_versions
                    SET description = NEW.description || ' ' || name
                    WHERE app_id = OLD.id;
                END IF;
            END IF;

            IF NEW.status != OLD.status THEN
                UPDATE config_model.application_versions
                SET status = NEW.status
                WHERE app_id = OLD.id;

                UPDATE config_model.connections
                SET status = NEW.status
                WHERE app_id = OLD.id;

                UPDATE config_model.application_instance
                SET status = NEW.status
                WHERE app_id = OLD.id;
            END IF;
        END IF;

        RETURN NEW;
    END;
    $function$
;


-- Table Triggers

CREATE TRIGGER trg_bu_applications BEFORE
INSERT
    OR
UPDATE
    ON
    config_model.applications FOR EACH ROW EXECUTE FUNCTION config_model.f_bu_applications();