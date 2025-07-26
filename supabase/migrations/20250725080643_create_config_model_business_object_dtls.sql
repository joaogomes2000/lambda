-- config_model.business_object_dtls definition

-- Drop table

-- DROP TABLE config_model.business_object_dtls;

CREATE TABLE config_model.business_object_dtls (
	id int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
	business_object_id int4 NULL,
	column_name varchar NULL,
	product_definition bool DEFAULT false NULL,
	create_user varchar DEFAULT CURRENT_USER NOT NULL,
	creation_date timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	update_user varchar NULL,
	update_date timestamp NULL,
	CONSTRAINT business_object_id_dtls_pkey PRIMARY KEY (id)
);

-- create function
-- DROP FUNCTION config_model.f_bu_generic();

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

CREATE TRIGGER trg_bu_business_object_id_dtls BEFORE
UPDATE
    ON
    config_model.business_object_dtls FOR EACH ROW EXECUTE FUNCTION config_model.f_bu_generic();


-- config_model.business_object_dtls foreign keys

ALTER TABLE config_model.business_object_dtls ADD CONSTRAINT business_object_id_fkey FOREIGN KEY (business_object_id) REFERENCES config_model.business_object(id) ON DELETE CASCADE;