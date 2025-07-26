-- config_model.protocol_type definition

-- Drop table

-- DROP TABLE config_model.protocol_type;

CREATE TABLE config_model.protocol_type (
	id int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
	"name" varchar NOT NULL,
	description varchar NOT NULL,
	status varchar(1) DEFAULT 'A'::character varying NOT NULL,
	create_user varchar DEFAULT CURRENT_USER NOT NULL,
	creation_date timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	update_user varchar NULL,
	update_date timestamp NULL,
	CONSTRAINT protocol_type_ck CHECK (((status)::text = ANY ((ARRAY['A'::character varying, 'I'::character varying])::text[]))),
	CONSTRAINT protocol_type_pk PRIMARY KEY (id)
);

-- create function

CREATE OR REPLACE FUNCTION config_model.f_bu_protocol_type()
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
                UPDATE config_model.connections
                SET status = NEW.status
                WHERE protocol_type_id = OLD.id;

                UPDATE config_model.attributes
                SET status = NEW.status
                WHERE protocol_type_id = OLD.id;

                UPDATE config_model.data_domain_app_versions
                SET status = NEW.status
                WHERE protocol_type_id = OLD.id;
            END IF;
        END IF;

        RETURN NEW;
    END;
    $function$
;


-- Table Triggers

CREATE TRIGGER trg_bu_protocol_type BEFORE
UPDATE
    ON
    config_model.protocol_type FOR EACH ROW EXECUTE FUNCTION config_model.f_bu_protocol_type();