-- config_model.schedule definition

-- Drop table

-- DROP TABLE config_model.schedule;

CREATE TABLE config_model.schedule (
	id int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
	orch_id int4 NOT NULL,
	frequency_mask varchar DEFAULT '* 1 * * *'::character varying NOT NULL,
	next_execution timestamp NULL,
	status varchar(1) DEFAULT 'A'::character varying NOT NULL,
	mark_as_deleted bool DEFAULT false NULL,
	create_user varchar DEFAULT CURRENT_USER NOT NULL,
	creation_date timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	update_user varchar NULL,
	update_date timestamp NULL,
	CONSTRAINT schedule_ck CHECK (((status)::text = ANY ((ARRAY['A'::character varying, 'I'::character varying])::text[]))),
	CONSTRAINT schedule_pk PRIMARY KEY (id)
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

CREATE TRIGGER trg_bu_schedule BEFORE
UPDATE
    ON
    config_model.schedule FOR EACH ROW EXECUTE FUNCTION config_model.f_bu_generic();


-- config_model.schedule foreign keys

ALTER TABLE config_model.schedule ADD CONSTRAINT schedule_orch_id_fkey FOREIGN KEY (orch_id) REFERENCES config_model.orch_head(id) ON DELETE CASCADE;