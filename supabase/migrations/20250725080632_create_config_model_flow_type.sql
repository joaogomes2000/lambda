-- config_model.flow_type definition

-- Drop table

-- DROP TABLE config_model.flow_type;

CREATE TABLE config_model.flow_type (
	id int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
	"name" varchar NOT NULL,
	description varchar NOT NULL,
	status varchar(1) DEFAULT 'A'::character varying NOT NULL,
	create_user varchar DEFAULT CURRENT_USER NOT NULL,
	creation_date timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	update_user varchar NULL,
	update_date timestamp NULL,
	CONSTRAINT flow_type_ck CHECK (((status)::text = ANY ((ARRAY['A'::character varying, 'I'::character varying])::text[]))),
	CONSTRAINT flow_type_pk PRIMARY KEY (id)
);

-- create function
-- DROP FUNCTION config_model.f_bu_flow_type();

CREATE OR REPLACE FUNCTION config_model.f_bu_flow_type()
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
                WHERE flow_type_id = OLD.id;
            END IF;
        END IF;

        RETURN NEW;
    END;
    $function$
;


-- Table Triggers

CREATE TRIGGER trg_bu_flow_type BEFORE
UPDATE
    ON
    config_model.flow_type FOR EACH ROW EXECUTE FUNCTION config_model.f_bu_flow_type();