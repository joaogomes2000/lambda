-- config_model.ctrl_orch_manager definition

-- Drop table

-- DROP TABLE config_model.ctrl_orch_manager;

CREATE TABLE config_model.ctrl_orch_manager (
	correlation_manager_id varchar NOT NULL,
	status varchar(1) DEFAULT 'N'::character varying NOT NULL,
	msg text NULL,
	begin_timestamp timestamp NULL,
	end_timestamp timestamp NULL,
	create_user varchar DEFAULT CURRENT_USER NOT NULL,
	creation_date timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	update_user varchar NULL,
	update_date timestamp NULL,
	CONSTRAINT ctrl_orch_manager_ck CHECK (((status)::text = ANY ((ARRAY['N'::character varying, 'W'::character varying, 'P'::character varying, 'E'::character varying])::text[]))),
	CONSTRAINT ctrl_orch_manager_pk PRIMARY KEY (correlation_manager_id)
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

CREATE TRIGGER trg_bu_ctrl_orch_manager BEFORE
UPDATE
    ON
    config_model.ctrl_orch_manager FOR EACH ROW EXECUTE FUNCTION config_model.f_bu_generic();