-- config_model."attributes" definition

-- Drop table

-- DROP TABLE config_model."attributes";

CREATE TABLE config_model."attributes" (
	id int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
	"name" varchar NOT NULL,
	description varchar NULL,
	protocol_type_id int4 NULL,
	flow_type_id int4 NULL,
	context varchar NOT NULL,
	attr_lov_id int4 NULL,
	required bool DEFAULT true NOT NULL,
	status varchar(1) DEFAULT 'A'::character varying NOT NULL,
	create_user varchar DEFAULT CURRENT_USER NOT NULL,
	creation_date timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	update_user varchar NULL,
	update_date timestamp NULL,
	mark_as_deleted bool DEFAULT false NULL,
	CONSTRAINT attributes_ck CHECK (((status)::text = ANY ((ARRAY['A'::character varying, 'I'::character varying])::text[]))),
	CONSTRAINT attributes_ck1 CHECK (((context)::text = ANY ((ARRAY['Connection'::character varying, 'DataDomain'::character varying, 'Step'::character varying, 'Availability'::character varying, 'StepAppInstance'::character varying])::text[]))),
	CONSTRAINT attributes_pk PRIMARY KEY (id)
);

-- create function
-- DROP FUNCTION config_model.f_aui_attributes();

CREATE OR REPLACE FUNCTION config_model.f_aui_attributes()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
   l_rec_row RECORD;
   l_rec_row_aux RECORD;
   l_exists BOOLEAN;
   l_attr_value varchar;
   l_aux_exists BOOLEAN;
   l_aux_attr_value varchar;
   v_protocol_type_name TEXT := '';
   v_flow_type_name TEXT := '';
BEGIN
   IF NEW.context != OLD.context then
      DELETE FROM config_model.data_domain_app_version_attrs
       WHERE attr_id = NEW.id;

      DELETE FROM config_model.orch_step_attrs
       WHERE attr_id = NEW.id;

      DELETE FROM config_model.connection_attrs
       WHERE attr_id = NEW.id;
   end if;

   IF NEW.context = 'Connection' THEN
      FOR l_rec_row IN SELECT *
                         FROM config_model.connections
                        WHERE (status = 'A' OR status = 'W')
                          AND protocol_type_id = NEW.protocol_type_id
                     ORDER BY id
      LOOP
         l_exists := FALSE;
         l_attr_value := NULL;

         IF TG_OP = 'UPDATE' and NEW.context = OLD.context then
            UPDATE config_model.connection_attrs
               SET status = NEW.status
                  ,required = NEW.required
             WHERE connection_id = l_rec_row.id
               AND attr_id = NEW.id;
         END IF;

         SELECT TRUE, attr_value
           INTO l_exists, l_attr_value
           FROM config_model.connection_attrs
          WHERE connection_id = l_rec_row.id
            AND attr_id = NEW.id;

         IF l_exists THEN
            IF NEW.required AND l_attr_value IS NULL THEN
               UPDATE config_model.connections c SET status = 'W' WHERE c.id = l_rec_row.id;
            END IF;
         ELSE
            INSERT INTO config_model.connection_attrs(connection_id, attr_id, required)
            values(l_rec_row.id, NEW.id, NEW.required);

            IF NEW.required then
               UPDATE config_model.connections c SET status = 'W' WHERE c.id = l_rec_row.id;
            END IF;
         END IF;
      END LOOP;
   ELSIF NEW.context = 'Availability' THEN
		FOR l_rec_row IN SELECT *
            FROM config_model.policies
            WHERE (status = 'A' OR status = 'W')
            ORDER BY id
      LOOP
         l_exists := FALSE;
         l_attr_value := NULL;

         IF TG_OP = 'UPDATE' and NEW.context = OLD.context then
            UPDATE config_model.policies_attrs
               SET status = NEW.status
                  ,required = NEW.required
             WHERE policy_id = l_rec_row.id
               AND attr_id = NEW.id;
         END IF;

         SELECT TRUE, attr_value
           INTO l_exists, l_attr_value
           FROM config_model.policies_attrs
          WHERE policy_id = l_rec_row.id
            AND attr_id = NEW.id;

         IF l_exists THEN
            IF NEW.required AND l_attr_value IS NULL THEN
               UPDATE config_model.policies c SET status = 'W' WHERE c.id = l_rec_row.id;
            END IF;
         ELSE
            INSERT INTO config_model.policies_attrs(policy_id, attr_id, required)
            values(l_rec_row.id, NEW.id, NEW.required);

            IF NEW.required then
               UPDATE config_model.policies c SET status = 'W' WHERE c.id = l_rec_row.id;
            END IF;
         END IF;
      END LOOP;
   ELSIF NEW.context = 'DataDomain' THEN
      FOR l_rec_row IN SELECT *
                         FROM config_model.data_domain_app_versions
                        WHERE (status = 'A' OR status = 'W')
                          AND protocol_type_id = NEW.protocol_type_id
                     ORDER BY id
      LOOP
         l_exists := FALSE;
         l_attr_value := NULL;

         IF TG_OP = 'UPDATE' and NEW.context = OLD.context then
            UPDATE config_model.data_domain_app_version_attrs
               SET status = NEW.status
                  ,required = NEW.required
             WHERE data_domain_app_version_id = l_rec_row.id
               AND attr_id = NEW.id;
         END IF;

         SELECT TRUE, attr_value
           INTO l_exists, l_attr_value
           FROM config_model.data_domain_app_version_attrs
          WHERE data_domain_app_version_id = l_rec_row.id
            AND attr_id = NEW.id;

         IF l_exists THEN
            IF NEW.required AND l_attr_value IS NULL THEN
               UPDATE config_model.data_domain_app_versions c SET status = 'W' WHERE c.id = l_rec_row.id;
            END IF;
         ELSE
            INSERT INTO config_model.data_domain_app_version_attrs(data_domain_app_version_id, attr_id, required)
            values(l_rec_row.id, NEW.id, NEW.required);

            IF NEW.required then
               UPDATE config_model.data_domain_app_versions c SET status = 'W' WHERE c.id = l_rec_row.id;
            END IF;
         END IF;
      END LOOP;
   end if;

   IF NEW.context = 'DataDomain' or NEW.context = 'Step' THEN
      FOR l_rec_row IN SELECT orch_steps.id
                         FROM config_model.orch_steps, config_model.data_domain_app_versions
                        WHERE (config_model.orch_steps.status = 'A' OR config_model.orch_steps.status = 'W')
                          AND orch_steps.data_domain_app_version_id = data_domain_app_versions.id
                          AND data_domain_app_versions.protocol_type_id = NEW.protocol_type_id
                     ORDER BY orch_steps.id
      LOOP
         l_exists := FALSE;
         l_attr_value := NULL;

         IF TG_OP = 'UPDATE' and NEW.context = OLD.context then
            UPDATE config_model.orch_step_attrs
               SET status = NEW.status
                  ,required = NEW.required
             WHERE orch_step_id = l_rec_row.id
               AND attr_id = NEW.id;
         END IF;

         SELECT TRUE, attr_value
           INTO l_exists, l_attr_value
           FROM config_model.orch_step_attrs
          WHERE orch_step_id = l_rec_row.id
            AND attr_id = NEW.id;

         IF l_exists THEN
            IF NEW.required AND l_attr_value IS NULL THEN
               UPDATE config_model.orch_steps c SET status = 'W' WHERE c.id = l_rec_row.id;
            END IF;
         ELSE
            INSERT INTO config_model.orch_step_attrs(orch_step_id, attr_id, required)
            values(l_rec_row.id, NEW.id, NEW.required);

            IF NEW.required then
               UPDATE config_model.orch_steps c SET status = 'W' WHERE c.id = l_rec_row.id;
            END IF;
         END IF;
      END LOOP;
   end if;

   IF NEW.context = 'DataDomain' or NEW.context = 'StepAppInstance' THEN
      FOR l_rec_row_aux IN SELECT orch_step_app_instances.id
                             FROM config_model.orch_step_app_instances
                            WHERE (config_model.orch_step_app_instances.status = 'A' OR config_model.orch_step_app_instances.status = 'W')
                              AND orch_step_app_instances.orch_step_id in (SELECT orch_steps.id
                                                                             FROM config_model.orch_steps, config_model.data_domain_app_versions
                                                                            WHERE (config_model.orch_steps.status = 'A' OR config_model.orch_steps.status = 'W')
                                                                              AND orch_steps.data_domain_app_version_id = data_domain_app_versions.id
                                                                              AND data_domain_app_versions.protocol_type_id = NEW.protocol_type_id
                                                                         ORDER BY orch_steps.id)
                         ORDER BY orch_step_app_instances.id
      LOOP
         l_aux_exists := FALSE;
         l_aux_attr_value := NULL;

         IF TG_OP = 'UPDATE' and NEW.context = OLD.context then
            UPDATE config_model.orch_step_app_instance_attrs
               SET status = NEW.status
                  ,required = NEW.required
             WHERE orch_step_app_instance_id = l_rec_row_aux.id
               AND attr_id = NEW.id;
         END IF;

         SELECT TRUE, attr_value
           INTO l_aux_exists, l_aux_attr_value
           FROM config_model.orch_step_app_instance_attrs
          WHERE orch_step_app_instance_id = l_rec_row_aux.id
            AND attr_id = NEW.id;

         IF l_aux_exists THEN
            IF NEW.required AND l_aux_attr_value IS NULL THEN
               UPDATE config_model.orch_step_app_instance_attrs c SET status = 'W' WHERE c.orch_step_app_instance_id = l_rec_row_aux.id;
            END IF;
         ELSE
            INSERT INTO config_model.orch_step_app_instance_attrs(orch_step_app_instance_id, attr_id, required)
            values(l_rec_row_aux.id, NEW.id, NEW.required);

            IF NEW.required then
               UPDATE config_model.orch_step_app_instance_attrs c SET status = 'W' WHERE c.orch_step_app_instance_id = l_rec_row_aux.id;
            END IF;
         END IF;
      END LOOP;
   END IF;


   RETURN NEW;
END;
$function$
;


CREATE OR REPLACE FUNCTION config_model.f_sync_attributes()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- Generate slug from domain_name if slug is null or empty

        INSERT INTO public."attributes"
   (id, attr_name, required, protocol_type, flow_type, attr_lov_id, context)
  SELECT NEW.id, NEW.name as attr_name, NEW.required, pt.name as protocol_type, ft."name" as flow_type, NEW.attr_lov_id, NEW.context
  FROM config_model.protocol_type pt
        LEFT JOIN config_model.flow_type ft on ft.id = new.flow_type_id
  WHERE pt.id = NEW.protocol_type_id;

    ELSIF TG_OP = 'UPDATE' THEN
        -- Generate slug from domain_name if slug is null or empty


         UPDATE public."attributes"
   SET attr_name = NEW.name,
     required = NEW.required,
    protocol_type = (select name  from config_model.protocol_type where id = new.protocol_type_id),
    flow_type = (select name  from config_model.flow_type where id = new.flow_type_id),
    attr_lov_id = NEW.attr_lov_id,
   context = NEW.context
   WHERE id = new.id;

    ELSIF TG_OP = 'DELETE' THEN
        delete from public."attributes"
        where id = old.id;

    END IF;

    RETURN NEW;
END;
$function$
;


-- Table Triggers

CREATE TRIGGER trg_sync_attributes AFTER
INSERT
    OR
DELETE
    OR
UPDATE
    ON
    config_model.attributes FOR EACH ROW EXECUTE FUNCTION config_model.f_sync_attributes();
CREATE TRIGGER trg_aui_attributes AFTER
INSERT
    OR
UPDATE
    ON
    config_model.attributes FOR EACH ROW EXECUTE FUNCTION config_model.f_aui_attributes();


-- config_model."attributes" foreign keys

ALTER TABLE config_model."attributes" ADD CONSTRAINT attributes_flow_type_id_fkey FOREIGN KEY (flow_type_id) REFERENCES config_model.flow_type(id) ON DELETE CASCADE;
ALTER TABLE config_model."attributes" ADD CONSTRAINT attributes_protocol_type_id_fkey FOREIGN KEY (protocol_type_id) REFERENCES config_model.protocol_type(id) ON DELETE CASCADE;