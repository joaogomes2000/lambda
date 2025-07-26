-- DROP FUNCTION public.f_sync_connections();

CREATE OR REPLACE FUNCTION public.f_sync_connections()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_status text := '';
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- Generate slug from domain_name if slug is null or empty

        INSERT INTO config_model.connections (
            app_id,
            protocol_type_id,
			description,
			reference_id
        )
        SELECT a.id,
		       p.id,
		       new.description,
		       new.id
		FROM config_model.protocol_type p 
		LEFT JOIN config_model.applications a ON a.reference_id = new.application_id
		WHERE p."name" = new."type"::text;



   /* ELSIF TG_OP = 'UPDATE' THEN
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
        WHERE id = NEW.id;*/

    ELSIF TG_OP = 'DELETE' THEN
        DELETE FROM config_model.connections
        WHERE reference_id = OLD.id;

        RETURN OLD;
    END IF;

    RETURN NEW;
END;
$function$
;



CREATE TRIGGER trg_sync_connections AFTER
INSERT
    OR
DELETE
    OR
UPDATE
    ON
    public.application_connectors FOR EACH ROW EXECUTE FUNCTION public.f_sync_connections();