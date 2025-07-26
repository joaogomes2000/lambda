-- config_model.data_domain_app_version_attrs definition

-- Drop table

-- DROP TABLE config_model.data_domain_app_version_attrs;

CREATE TABLE config_model.data_domain_app_version_attrs (
	id int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
	data_domain_app_version_id int4 NOT NULL,
	attr_id int4 NOT NULL,
	attr_value varchar NULL,
	required bool DEFAULT false NOT NULL,
	status varchar(1) DEFAULT 'A'::character varying NOT NULL,
	create_user varchar DEFAULT CURRENT_USER NOT NULL,
	creation_date timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	update_user varchar NULL,
	update_date timestamp NULL,
	CONSTRAINT data_domain_app_version_attrs_ck CHECK (((status)::text = ANY ((ARRAY['A'::character varying, 'I'::character varying])::text[]))),
	CONSTRAINT data_domain_app_version_attrs_pk PRIMARY KEY (id)
);

-- create function

CREATE OR REPLACE FUNCTION config_model.f_bu_data_domain_version_attrs()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    DECLARE
        l_attr_lov_id INT := NULL;
        l_exists INT := NULL;
    BEGIN
        IF TG_OP = 'UPDATE' AND NEW.attr_value IS NOT NULL THEN
            SELECT attr_lov_id
            INTO l_attr_lov_id
            FROM config_model.attributes
            WHERE id = NEW.attr_id
                AND attr_lov_id IS NOT NULL;

            IF l_attr_lov_id IS NOT NULL THEN
                SELECT 1
                INTO l_exists
                FROM config_model.attributes_lov
                WHERE attr_lov_id = l_attr_lov_id
                    AND value = NEW.attr_value;

                IF l_exists IS NULL THEN
                    RAISE EXCEPTION 'Error: Value not found in List of Values';
                    RETURN NULL;
                END IF;
            END IF;

            IF NEW.update_user IS NULL OR NEW.update_user = '' THEN
                NEW.update_user := current_user;
            END IF;
            NEW.update_date := current_timestamp;
        END IF;

        RETURN NEW;
    END;
    $function$
;


-- Table Triggers

CREATE TRIGGER trg_bu_data_domain_version_attrs BEFORE
UPDATE
    ON
    config_model.data_domain_app_version_attrs FOR EACH ROW EXECUTE FUNCTION config_model.f_bu_data_domain_version_attrs();


-- config_model.data_domain_app_version_attrs foreign keys

ALTER TABLE config_model.data_domain_app_version_attrs ADD CONSTRAINT data_domain_app_version_attrs_attr_id_fkey FOREIGN KEY (attr_id) REFERENCES config_model."attributes"(id) ON DELETE CASCADE;
ALTER TABLE config_model.data_domain_app_version_attrs ADD CONSTRAINT data_domain_app_version_attrs_data_domain_app_version_id_fkey FOREIGN KEY (data_domain_app_version_id) REFERENCES config_model.data_domain_app_versions(id) ON DELETE CASCADE;