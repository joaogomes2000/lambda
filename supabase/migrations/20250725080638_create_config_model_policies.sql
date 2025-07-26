-- config_model.policies definition

-- Drop table

-- DROP TABLE config_model.policies;

CREATE TABLE config_model.policies (
	id int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
	"name" varchar NOT NULL,
	description varchar NULL,
	status varchar(1) DEFAULT 'A'::character varying NOT NULL,
	create_user varchar DEFAULT CURRENT_USER NOT NULL,
	create_date timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	update_user varchar NULL,
	update_date timestamp NULL,
	CONSTRAINT policies_pkey PRIMARY KEY (id),
	CONSTRAINT policies_status_check CHECK (((status)::text = ANY ((ARRAY['A'::character varying, 'I'::character varying, 'W'::character varying])::text[])))
);

-- create function

CREATE OR REPLACE FUNCTION config_model.f_ai_policies()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    DECLARE
        l_rec_row RECORD;
    BEGIN
        IF TG_OP = 'INSERT' THEN
            FOR l_rec_row IN
                SELECT id, required
                FROM config_model.attributes
                WHERE context = 'Availability'
                ORDER BY id
            LOOP
                INSERT INTO config_model.policies_attrs(policy_id, attr_id, required)
                VALUES (NEW.id, l_rec_row.id, l_rec_row.required);
            END LOOP;
        END IF;
        RETURN NEW;
    END;
    $function$
;


CREATE OR REPLACE FUNCTION config_model.f_biu_policies()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    DECLARE
        l_app_name VARCHAR;
        l_protocol_name VARCHAR;
    BEGIN
        IF TG_OP = 'UPDATE' THEN
            IF NEW.update_user IS NULL OR NEW.update_user = '' THEN
                NEW.update_user := current_user;
            END IF;
            NEW.update_date := current_timestamp;

            IF NEW.status != OLD.status AND NEW.status != 'W' THEN
                UPDATE config_model.policies_attrs
                SET status = NEW.status
                WHERE policy_id = OLD.id;
            END IF;
        END IF;

        RETURN NEW;
    END;
    $function$
;



-- Table Triggers

CREATE TRIGGER trg_ai_policies AFTER
INSERT
    ON
    config_model.policies FOR EACH ROW EXECUTE FUNCTION config_model.f_ai_policies();
CREATE TRIGGER trg_biu_policies BEFORE
INSERT
    OR
UPDATE
    ON
    config_model.policies FOR EACH ROW EXECUTE FUNCTION config_model.f_biu_policies();