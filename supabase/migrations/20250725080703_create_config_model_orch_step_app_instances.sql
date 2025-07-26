-- config_model.orch_step_app_instances definition

-- Drop table

-- DROP TABLE config_model.orch_step_app_instances;

CREATE TABLE config_model.orch_step_app_instances (
	id int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
	orch_step_id int4 NOT NULL,
	app_instance_id int4 NOT NULL,
	connection_id int4 NULL,
	status varchar(1) DEFAULT 'A'::character varying NOT NULL,
	create_user varchar DEFAULT CURRENT_USER NOT NULL,
	creation_date timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	update_user varchar NULL,
	update_date timestamp NULL,
	CONSTRAINT orch_step_targets_ck CHECK (((status)::text = ANY ((ARRAY['A'::character varying, 'I'::character varying])::text[]))),
	CONSTRAINT orch_step_targets_pk PRIMARY KEY (id)
);

-- create function

CREATE OR REPLACE FUNCTION config_model.f_aui_orch_step_app_instances()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    DECLARE
        l_rec_row RECORD;
        l_flow_type_id_app_version INT;
        l_protocol_type_id_app_version INT;
        l_app_version_id INT;
        l_data_domain_id INT;
        l_exists INT;
    BEGIN
        IF TG_OP = 'UPDATE' THEN
            UPDATE config_model.orch_step_app_instance_attrs
            SET status = NEW.status
            WHERE orch_step_app_instance_id = OLD.id;
        END IF;

        IF TG_OP = 'INSERT' THEN
            SELECT flow_type_id, protocol_type_id, app_version_id, data_domain_id
            INTO l_flow_type_id_app_version, l_protocol_type_id_app_version, l_app_version_id, l_data_domain_id
            FROM config_model.data_domain_app_versions ddav
            WHERE ddav.id = (SELECT data_domain_app_version_id FROM config_model.orch_steps WHERE id = NEW.orch_step_id);

            FOR l_rec_row IN
                SELECT a.id, a.required
                FROM config_model.ATTRIBUTES a
                JOIN config_model.data_domain_app_versions ddav ON ddav.id = (SELECT data_domain_app_version_id FROM config_model.orch_steps WHERE id = NEW.orch_step_id)
                WHERE (a.protocol_type_id IS NULL OR a.protocol_type_id = l_protocol_type_id_app_version)
                      AND (context = 'DataDomain' OR context = 'Step' OR context = 'StepAppInstance')
                ORDER BY a.id
            LOOP
                INSERT INTO config_model.orch_step_app_instance_attrs (orch_step_app_instance_id, attr_id, required)
                VALUES (NEW.id, l_rec_row.id, l_rec_row.required);
            END LOOP;

            SELECT 1 INTO l_exists
            FROM config_model.flow_type
            WHERE id = l_flow_type_id_app_version
                  AND name = 'outbound';

            IF l_exists = 1 THEN
                SELECT 1 INTO l_exists
                FROM config_model.sequences_ctrl
                WHERE app_version_id = l_app_version_id
                      AND app_instance_id = NEW.app_instance_id
                      AND data_domain_id = l_data_domain_id
                      AND protocol_type_id = l_protocol_type_id_app_version;

                IF l_exists IS NULL THEN
                    INSERT INTO config_model.sequences_ctrl(app_version_id, app_instance_id, data_domain_id, protocol_type_id)
                    VALUES (l_app_version_id, NEW.app_instance_id, l_data_domain_id, l_protocol_type_id_app_version);
                END IF;
            END IF;
        END IF;

        RETURN NEW;
    END;
    $function$
;


-- Table Triggers

CREATE TRIGGER trg_aui_orch_step_app_instances AFTER
INSERT
    OR
UPDATE
    ON
    config_model.orch_step_app_instances FOR EACH ROW EXECUTE FUNCTION config_model.f_aui_orch_step_app_instances();


-- config_model.orch_step_app_instances foreign keys

ALTER TABLE config_model.orch_step_app_instances ADD CONSTRAINT orch_step_app_instances_application_instance_id_fkey FOREIGN KEY (app_instance_id) REFERENCES config_model.application_instance(id) ON DELETE CASCADE;
ALTER TABLE config_model.orch_step_app_instances ADD CONSTRAINT orch_step_app_instances_connections_fk FOREIGN KEY (connection_id) REFERENCES config_model.connections(id) ON DELETE CASCADE;
ALTER TABLE config_model.orch_step_app_instances ADD CONSTRAINT orch_step_app_instances_orch_step_id_fkey FOREIGN KEY (orch_step_id) REFERENCES config_model.orch_steps(id) ON DELETE CASCADE;