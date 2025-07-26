-- config_model.data_domain_app_versions definition

-- Drop table

-- DROP TABLE config_model.data_domain_app_versions;

CREATE TABLE config_model.data_domain_app_versions (
	id int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
	app_version_id int4 NOT NULL,
	data_domain_id int4 NOT NULL,
	protocol_type_id int4 NOT NULL,
	flow_type_id int4 NULL,
	data_domain_mapping_id int4 NULL,
	product_definition bool DEFAULT false NOT NULL,
	status varchar(1) DEFAULT 'A'::character varying NOT NULL,
	mark_as_deleted bool DEFAULT false NULL,
	create_user varchar DEFAULT CURRENT_USER NOT NULL,
	creation_date timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	update_user varchar NULL,
	update_date timestamp NULL,
	CONSTRAINT data_domain_app_versions_ck CHECK (((status)::text = ANY ((ARRAY['A'::character varying, 'I'::character varying, 'W'::character varying])::text[]))),
	CONSTRAINT data_domain_app_versions_pk PRIMARY KEY (id)
);

-- create function

CREATE OR REPLACE FUNCTION config_model.f_aui_data_domain_app_versions()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
   l_rec_row RECORD;
   l_exists int := 0;
   v_protocol_type_name TEXT := '';
	v_flow_type_name TEXT := '';
begin
   IF TG_OP = 'INSERT' or (TG_OP = 'UPDATE' AND NEW.protocol_type_id != OLD.protocol_type_id) THEN
      FOR l_rec_row IN SELECT a.id, a.required
                         FROM config_model.ATTRIBUTES a
                        WHERE (a.protocol_type_id IS NULL OR a.protocol_type_id = NEW.protocol_type_id)
                          AND context = 'DataDomain'
                          and (a.flow_type_id is null or flow_type_id = NEW.flow_type_id)
                     ORDER BY id
      LOOP
         INSERT INTO config_model.data_domain_app_version_attrs(data_domain_app_version_id, attr_id, required, create_user, creation_date)
         values(NEW.id, l_rec_row.id, l_rec_row.required, NEW.create_user, NEW.creation_date);
      END LOOP;

      select 1
        into l_exists
        from config_model.flow_type
       where id = NEW.flow_type_id
        and name = 'outbound';

      if l_exists = 1 then
         select 1
           into l_exists
           From config_model.sequences_ctrl
          where app_version_id = NEW.app_version_id
            and data_domain_id = NEW.data_domain_id
            and protocol_type_id = NEW.protocol_type_id;

         if l_exists is null then
            insert into config_model.sequences_ctrl(app_version_id, data_domain_id, protocol_type_id) values(NEW.app_version_id, NEW.data_domain_id, NEW.protocol_type_id);
         end if;
      end if;
   end if;

   RETURN NEW;
END
$function$
;

CREATE OR REPLACE FUNCTION config_model.f_bu_data_domain_app_versions()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
        IF TG_OP = 'UPDATE' THEN
            IF NEW.update_user IS NULL OR NEW.update_user = '' THEN
                NEW.update_user := current_user;
            END IF;
            NEW.update_date := current_timestamp;

            IF NEW.status != OLD.status AND NEW.status != 'W' THEN
                UPDATE config_model.data_domain_app_version_attrs
                SET status = NEW.status
                WHERE data_domain_app_version_id = OLD.id;

                UPDATE config_model.orch_steps
                SET status = NEW.status
                WHERE data_domain_app_version_id = OLD.id;
            END IF;
        END IF;

        IF TG_OP = 'UPDATE' AND NEW.protocol_type_id != OLD.protocol_type_id THEN
            DELETE FROM config_model.data_domain_app_version_attrs
            WHERE data_domain_app_version_id = NEW.id;
        END IF;

        RETURN NEW;
    END;
    $function$
;


-- Table Triggers

CREATE TRIGGER trg_aui_data_domain_app_versions AFTER
INSERT
    OR
UPDATE
    ON
    config_model.data_domain_app_versions FOR EACH ROW EXECUTE FUNCTION config_model.f_aui_data_domain_app_versions();
CREATE TRIGGER trg_bu_data_domain_app_versions BEFORE
UPDATE
    ON
    config_model.data_domain_app_versions FOR EACH ROW EXECUTE FUNCTION config_model.f_bu_data_domain_app_versions();


-- config_model.data_domain_app_versions foreign keys

ALTER TABLE config_model.data_domain_app_versions ADD CONSTRAINT data_domain_app_versions_app_version_id_fkey FOREIGN KEY (app_version_id) REFERENCES config_model.application_versions(id) ON DELETE CASCADE;
ALTER TABLE config_model.data_domain_app_versions ADD CONSTRAINT data_domain_app_versions_data_domain_id_fkey FOREIGN KEY (data_domain_id) REFERENCES config_model.data_domains(id) ON DELETE CASCADE;
ALTER TABLE config_model.data_domain_app_versions ADD CONSTRAINT data_domain_app_versions_data_domain_mapping_id_fkey FOREIGN KEY (data_domain_mapping_id) REFERENCES config_model.data_domain_mapping(id) ON DELETE CASCADE;
ALTER TABLE config_model.data_domain_app_versions ADD CONSTRAINT data_domain_app_versions_flow_type_fk FOREIGN KEY (flow_type_id) REFERENCES config_model.flow_type(id) ON DELETE CASCADE;
ALTER TABLE config_model.data_domain_app_versions ADD CONSTRAINT data_domain_app_versions_protocol_type_id_fkey FOREIGN KEY (protocol_type_id) REFERENCES config_model.protocol_type(id) ON DELETE CASCADE;