-- config_model.attributes_lov definition

-- Drop table

-- DROP TABLE config_model.attributes_lov;

CREATE TABLE config_model.attributes_lov (
	id int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
	attr_lov_id serial4 NOT NULL,
	"name" varchar NOT NULL,
	value varchar NULL,
	status varchar(1) DEFAULT 'A'::character varying NOT NULL,
	create_user varchar DEFAULT CURRENT_USER NOT NULL,
	creation_date timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	update_user varchar NULL,
	update_date timestamp NULL,
	CONSTRAINT attributes_lov_ck CHECK (((status)::text = ANY ((ARRAY['A'::character varying, 'I'::character varying])::text[]))),
	CONSTRAINT attributes_lov_pk PRIMARY KEY (attr_lov_id, id)
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


-- DROP FUNCTION config_model.f_sync_attributes_lov();

CREATE OR REPLACE FUNCTION config_model.f_sync_attributes_lov()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- Generate slug from domain_name if slug is null or empty

        INSERT INTO public.attributes_lov
		(id, attr_lov_id, value, "label")
		VALUES(NEW.id, NEW.attr_lov_id, new.value, new.name);

    ELSIF TG_OP = 'UPDATE' THEN
        -- Generate slug from domain_name if slug is null or empty

		 IF NEW.status != OLD.status THEN
			UPDATE public.attributes_lov
			 SET status = (CASE NEW.status
						        WHEN 'A' THEN 'Activate'
						        WHEN 'I' THEN 'Inactive'
						    END)
			 WHERE id = NEW.id;
		 END IF;
		 UPDATE public.attributes_lov
		 SET attr_lov_id = NEW.attr_lov_id,
			 value = NEW.value,
			 "label"=  NEW.name
		 WHERE id = NEW.id;

    ELSIF TG_OP = 'DELETE' THEN
       	DELETE FROM public.attributes_lov
        WHERE id = OLD.id;

    END IF;

    RETURN NEW;
END;
$function$
;



-- Table Triggers

CREATE TRIGGER trg_sync_attributes_lov AFTER
INSERT
    OR
DELETE
    OR
UPDATE
    ON
    config_model.attributes_lov FOR EACH ROW EXECUTE FUNCTION config_model.f_sync_attributes_lov();
CREATE TRIGGER trg_bu_attributes_lov BEFORE
UPDATE
    ON
    config_model.attributes_lov FOR EACH ROW EXECUTE FUNCTION config_model.f_bu_generic();