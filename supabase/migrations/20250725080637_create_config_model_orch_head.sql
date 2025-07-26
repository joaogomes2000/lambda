-- config_model.orch_head definition

-- Drop table

-- DROP TABLE config_model.orch_head;

CREATE TABLE config_model.orch_head (
	id int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
	"name" varchar NOT NULL,
	description varchar NULL,
	nrt_ind bool DEFAULT false NOT NULL,
	status varchar(1) DEFAULT 'A'::character varying NOT NULL,
	reference_id int4 NULL,
	mark_as_deleted bool DEFAULT false NULL,
	create_user varchar DEFAULT CURRENT_USER NOT NULL,
	creation_date timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	update_user varchar NULL,
	update_date timestamp NULL,
	CONSTRAINT orch_head_ck CHECK (((status)::text = ANY ((ARRAY['A'::character varying, 'I'::character varying, 'W'::character varying])::text[]))),
	CONSTRAINT orch_head_pk PRIMARY KEY (id)
);

-- create function
-- DROP FUNCTION config_model.f_au_orch_head();

CREATE OR REPLACE FUNCTION config_model.f_au_orch_head()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
        IF TG_OP = 'UPDATE' THEN
            NEW.update_user := current_user;
            NEW.update_date := CURRENT_TIMESTAMP;

            IF OLD.status != NEW.status AND NEW.status != 'W' THEN
                UPDATE config_model.orch_steps
                SET status = NEW.status
                WHERE orch_id = OLD.id;

                UPDATE config_model.schedule
                SET status = NEW.status
                WHERE orch_id = OLD.id;
            END IF;
        END IF;

        RETURN NEW;
    END;
    $function$
;


-- Table Triggers

CREATE TRIGGER trg_au_orch_head AFTER
UPDATE
    ON
    config_model.orch_head FOR EACH ROW EXECUTE FUNCTION config_model.f_au_orch_head();