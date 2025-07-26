-- config_model.data_domains definition

-- Drop table

-- DROP TABLE config_model.data_domains;

CREATE TABLE config_model.data_domains (
	id int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
	domain_name varchar NOT NULL,
	customer_domain_label varchar NULL,
	domain_model text NOT NULL,
	product_definition bool DEFAULT true NULL,
	status varchar(1) DEFAULT 'A'::character varying NOT NULL,
	mark_as_deleted bool DEFAULT false NULL,
	create_user varchar DEFAULT CURRENT_USER NOT NULL,
	creation_date timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	update_user varchar NULL,
	update_date timestamp NULL,
	CONSTRAINT data_domains_ck CHECK (((status)::text = ANY ((ARRAY['A'::character varying, 'I'::character varying])::text[]))),
	CONSTRAINT data_domains_pk PRIMARY KEY (id)
);

-- create function

CREATE OR REPLACE FUNCTION config_model.f_ai_data_domains()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
        IF TG_OP = 'INSERT' THEN
            IF NEW.product_definition = FALSE THEN
                INSERT INTO config_model.data_domain_app_versions (
                    app_version_id, data_domain_id, protocol_type_id, flow_type_id, product_definition
                )
                VALUES (
                    (SELECT id FROM config_model.application_versions WHERE app_id = (SELECT id FROM config_model.applications WHERE name = 'katalist')),
                    NEW.id,
                    (SELECT id FROM config_model.protocol_type WHERE name = 'sync'),
                    (SELECT id FROM config_model.flow_type WHERE name = 'internal'),
                    NEW.product_definition
                );
            END IF;
        END IF;

        RETURN NEW;
    END;
    $function$
;


CREATE OR REPLACE FUNCTION config_model.f_bu_data_domains()
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
                WHERE data_domain_id = OLD.id;
            END IF;
        END IF;

        RETURN NEW;
    END;
    $function$
;


CREATE OR REPLACE FUNCTION config_model.f_sync_data_domains()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_status text := '';
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- Generate slug from domain_name if slug is null or empty

        INSERT INTO public.entities (
            id,
            name,
            slug,
			description,
			mark_as_deleted
        )
        VALUES (
            NEW.id,
            NEW.domain_name,
            LOWER(REGEXP_REPLACE(TRIM(NEW.domain_name), '\s+', '-', 'g')),
			new.domain_name,
            NEW.mark_as_deleted
        );

    ELSIF TG_OP = 'UPDATE' THEN
        -- Generate slug from domain_name if slug is null or empty
        if new.status != old.status THEN
		    v_status :=  CASE NEW.status
					        WHEN 'A' THEN 'Activate'
					        WHEN 'I' THEN 'Inactive'
					    END;
	    	UPDATE public.entities
			set status = v_status
			where id = new.id;
		END IF;

		UPDATE public.entities
        SET
            name = NEW.domain_name,
            slug = LOWER(REGEXP_REPLACE(TRIM(NEW.domain_name), '\s+', '-', 'g')),
			description = NEW.domain_name,
            mark_as_deleted = NEW.mark_as_deleted
        WHERE id = NEW.id;

    ELSIF TG_OP = 'DELETE' THEN
        DELETE FROM public.entities
        WHERE id = OLD.id;

        RETURN OLD;
    END IF;

    RETURN NEW;
END;
$function$
;


-- Table Triggers

CREATE TRIGGER trg_sync_data_domains AFTER
INSERT
    OR
DELETE
    OR
UPDATE
    ON
    config_model.data_domains FOR EACH ROW EXECUTE FUNCTION config_model.f_sync_data_domains();
CREATE TRIGGER trg_ai_data_domains AFTER
INSERT
    OR
UPDATE
    ON
    config_model.data_domains FOR EACH ROW EXECUTE FUNCTION config_model.f_ai_data_domains();
CREATE TRIGGER trg_bu_data_domains BEFORE
UPDATE
    ON
    config_model.data_domains FOR EACH ROW EXECUTE FUNCTION config_model.f_bu_data_domains();