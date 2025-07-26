-- config_model.policies_attrs definition

-- Drop table

-- DROP TABLE config_model.policies_attrs;

CREATE TABLE config_model.policies_attrs (
	id int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
	policy_id int4 NULL,
	attr_id int4 NULL,
	attr_value varchar NULL,
	required bool NOT NULL,
	status varchar(1) DEFAULT 'A'::character varying NOT NULL,
	create_user varchar DEFAULT CURRENT_USER NOT NULL,
	create_date timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	update_user varchar NULL,
	update_date timestamp NULL,
	CONSTRAINT policies_attrs_pkey PRIMARY KEY (id),
	CONSTRAINT policies_attrs_status_check CHECK (((status)::text = ANY ((ARRAY['A'::character varying, 'I'::character varying, 'W'::character varying])::text[])))
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

CREATE TRIGGER trg_bu_policies_attrs BEFORE
INSERT
    OR
UPDATE
    ON
    config_model.policies_attrs FOR EACH ROW EXECUTE FUNCTION config_model.f_bu_generic();


-- config_model.policies_attrs foreign keys

ALTER TABLE config_model.policies_attrs ADD CONSTRAINT policies_attrs_attr_id_fkey FOREIGN KEY (attr_id) REFERENCES config_model."attributes"(id) ON DELETE CASCADE;
ALTER TABLE config_model.policies_attrs ADD CONSTRAINT policies_attrs_policy_id_fkey FOREIGN KEY (policy_id) REFERENCES config_model.policies(id) ON DELETE CASCADE;