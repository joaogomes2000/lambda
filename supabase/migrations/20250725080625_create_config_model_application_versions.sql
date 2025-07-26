-- config_model.application_versions definition

-- Drop table

-- DROP TABLE config_model.application_versions;

CREATE TABLE config_model.application_versions (
	id int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
	app_id int4 NOT NULL,
	"name" varchar DEFAULT 'V1.0'::character varying NOT NULL,
	description varchar NULL,
	product_definition bool DEFAULT false NULL,
	status varchar(1) DEFAULT 'A'::character varying NOT NULL,
	mark_as_deleted bool DEFAULT false NULL,
	create_user varchar DEFAULT CURRENT_USER NOT NULL,
	creation_date timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	update_user varchar NULL,
	update_date timestamp NULL,
	CONSTRAINT application_versions_ck CHECK (((status)::text = ANY ((ARRAY['A'::character varying, 'I'::character varying])::text[]))),
	CONSTRAINT application_versions_pk PRIMARY KEY (id)
);
CREATE INDEX application_versions_name_idx ON config_model.application_versions USING btree (name, description, app_id);

-- create function
-- DROP FUNCTION config_model.f_biu_application_versions();

CREATE OR REPLACE FUNCTION config_model.f_biu_application_versions()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    DECLARE
        l_app_name VARCHAR;
    BEGIN
        IF TG_OP = 'INSERT' AND NEW.description IS NULL THEN
            SELECT description
            INTO l_app_name
            FROM config_model.applications
            WHERE id = NEW.app_id;

            NEW.description := l_app_name || ' ' || NEW.name;
        ELSIF TG_OP = 'UPDATE' THEN
            NEW.update_user := CURRENT_USER;
            NEW.update_date := CURRENT_TIMESTAMP;

            IF NEW.status != OLD.status THEN
                UPDATE config_model.data_domain_app_versions
                SET status = NEW.status
                WHERE app_version_id = OLD.id;
            END IF;
        END IF;

        RETURN NEW;
    END;
    $function$
;


-- Table Triggers

CREATE TRIGGER trg_biu_application_versions BEFORE
INSERT
    OR
UPDATE
    ON
    config_model.application_versions FOR EACH ROW EXECUTE FUNCTION config_model.f_biu_application_versions();


-- config_model.application_versions foreign keys

ALTER TABLE config_model.application_versions ADD CONSTRAINT application_versions_app_id_fkey FOREIGN KEY (app_id) REFERENCES config_model.applications(id) ON DELETE CASCADE;