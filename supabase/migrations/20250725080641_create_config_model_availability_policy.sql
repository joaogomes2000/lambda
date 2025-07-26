-- config_model.availability_policy definition

-- Drop table

-- DROP TABLE config_model.availability_policy;

CREATE TABLE config_model.availability_policy (
	id int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
	"name" varchar NOT NULL,
	description varchar NULL,
	alert_rule varchar NULL,
	severity varchar NULL,
	context varchar NOT NULL,
	error_code_id varchar NULL,
	policy_id int4 NULL,
	status varchar(1) DEFAULT 'A'::character varying NOT NULL,
	mark_as_deleted bool DEFAULT false NULL,
	create_user varchar DEFAULT CURRENT_USER NOT NULL,
	create_date timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	update_user varchar NULL,
	update_date timestamp NULL,
	CONSTRAINT availability_policy_context_check CHECK (((context)::text = ANY ((ARRAY['Database'::character varying, 'Storage'::character varying, 'Functions'::character varying])::text[]))),
	CONSTRAINT availability_policy_pkey PRIMARY KEY (id),
	CONSTRAINT availability_policy_status_check CHECK (((status)::text = ANY ((ARRAY['A'::character varying, 'I'::character varying, 'W'::character varying])::text[])))
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

CREATE TRIGGER trg_bu_availability_policy BEFORE
INSERT
    OR
UPDATE
    ON
    config_model.availability_policy FOR EACH ROW EXECUTE FUNCTION config_model.f_bu_generic();


-- config_model.availability_policy foreign keys

ALTER TABLE config_model.availability_policy ADD CONSTRAINT availability_policy_policy_id_fkey FOREIGN KEY (policy_id) REFERENCES config_model.policies(id) ON DELETE CASCADE;