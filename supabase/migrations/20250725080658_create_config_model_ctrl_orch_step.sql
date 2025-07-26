-- config_model.ctrl_orch_step definition

-- Drop table

-- DROP TABLE config_model.ctrl_orch_step;

CREATE TABLE config_model.ctrl_orch_step (
	correlation_id varchar NOT NULL,
	orch_id int4 NOT NULL,
	orch_step_id int4 NOT NULL,
	parallel_ind bool DEFAULT false NOT NULL,
	msg text NULL,
	status varchar(1) DEFAULT 'Q'::character varying NOT NULL,
	begin_timestamp timestamp NULL,
	end_timestamp timestamp NULL,
	create_user varchar DEFAULT CURRENT_USER NULL,
	creation_date timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	update_user varchar NULL,
	update_date timestamp NULL,
	CONSTRAINT ctrl_orch_step_ck CHECK (((status)::text = ANY ((ARRAY['R'::character varying, 'Q'::character varying, 'W'::character varying, 'P'::character varying, 'E'::character varying])::text[]))),
	CONSTRAINT ctrl_orch_step_pk PRIMARY KEY (correlation_id, orch_id, orch_step_id)
);

-- create function
-- DROP FUNCTION config_model.f_bu_ctrl_orch_step();

CREATE OR REPLACE FUNCTION config_model.f_bu_ctrl_orch_step()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    DECLARE
        l_query TEXT := '';
        l_msg TEXT := '';
    BEGIN
        IF TG_OP = 'UPDATE' THEN
            IF NEW.update_user IS NULL OR NEW.update_user = '' THEN
                NEW.update_user := current_user;
            END IF;
            NEW.update_date := CURRENT_TIMESTAMP;
        END IF;

        IF NEW.status = 'E' THEN
            l_msg := format('Error while running step number: %s', OLD.orch_step_id);
            l_query := format('UPDATE config_model.ctrl_orch SET status = ''E'', msg = %L WHERE correlation_id = %L', l_msg, OLD.correlation_id);
            EXECUTE l_query;
        END IF;

        RETURN NEW;
    END;
    $function$
;


-- Table Triggers

CREATE TRIGGER trg_bu_ctrl_orch_step BEFORE
UPDATE
    ON
    config_model.ctrl_orch_step FOR EACH ROW EXECUTE FUNCTION config_model.f_bu_ctrl_orch_step();


-- config_model.ctrl_orch_step foreign keys

ALTER TABLE config_model.ctrl_orch_step ADD CONSTRAINT ctrl_orch_step_correlation_id_fkey FOREIGN KEY (correlation_id) REFERENCES config_model.ctrl_orch(correlation_id) ON DELETE CASCADE;
ALTER TABLE config_model.ctrl_orch_step ADD CONSTRAINT ctrl_orch_step_orch_id_fkey FOREIGN KEY (orch_id) REFERENCES config_model.orch_head(id) ON DELETE CASCADE;
ALTER TABLE config_model.ctrl_orch_step ADD CONSTRAINT ctrl_orch_step_orch_steps_fk FOREIGN KEY (orch_step_id) REFERENCES config_model.orch_steps(id) ON DELETE CASCADE;