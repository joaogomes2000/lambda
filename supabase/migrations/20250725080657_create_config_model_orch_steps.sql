-- config_model.orch_steps definition

-- Drop table

-- DROP TABLE config_model.orch_steps;

CREATE TABLE config_model.orch_steps (
	id int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
	orch_id int4 NOT NULL,
	orch_step int4 NOT NULL,
	"name" varchar NOT NULL,
	data_domain_app_version_id int4 NOT NULL,
	connection_id int4 NULL,
	parallel_ind bool DEFAULT false NOT NULL,
	status varchar(1) DEFAULT 'A'::character varying NOT NULL,
	mark_as_deleted bool DEFAULT false NULL,
	create_user varchar DEFAULT CURRENT_USER NOT NULL,
	creation_date timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	update_user varchar NULL,
	update_date timestamp NULL,
	CONSTRAINT orch_steps_pk PRIMARY KEY (id)
);
CREATE UNIQUE INDEX idx_unique_orch_id_step_active ON config_model.orch_steps USING btree (orch_id, orch_step) WHERE ((status)::text = 'A'::text);

-- create function

CREATE OR REPLACE FUNCTION config_model.f_aui_orch_steps()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    DECLARE
        l_rec_row RECORD;
        l_rec_row_aux RECORD;
        l_protocol_type_id_app_version INT;
        l_flow_type_id_app_version INT;
        l_count_status INT;
    BEGIN
        IF TG_OP = 'UPDATE' THEN
            IF NEW.status = 'I' THEN
                SELECT count(1)
                INTO l_count_status
                FROM config_model.orch_steps
                WHERE status IN ('A');

                IF l_count_status = 0 THEN
                    UPDATE config_model.orch_head
                    SET status = 'W'
                    WHERE id = OLD.orch_id;
                END IF;
            END IF;
        END IF;

        IF TG_OP = 'UPDATE' AND OLD.data_domain_app_version_id != NEW.data_domain_app_version_id THEN
            UPDATE config_model.orch_step_attrs
            SET status = 'I'
            WHERE orch_step_id = OLD.id;

            UPDATE config_model.orch_step_app_instance_attrs
            SET status = 'I'
            WHERE orch_step_app_instance_id IN (
                SELECT id
                FROM config_model.orch_step_app_instances
                WHERE orch_step_id = OLD.id
            );
        END IF;

        IF TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND OLD.data_domain_app_version_id != NEW.data_domain_app_version_id) THEN
            SELECT protocol_type_id, flow_type_id
            INTO l_protocol_type_id_app_version, l_flow_type_id_app_version
            FROM config_model.data_domain_app_versions ddav
            WHERE ddav.id = NEW.data_domain_app_version_id;

            FOR l_rec_row IN
                SELECT a.id, a.required
                FROM config_model.ATTRIBUTES a
                JOIN config_model.data_domain_app_versions ddav ON ddav.id = NEW.data_domain_app_version_id
                WHERE (a.protocol_type_id IS NULL
                    OR a.protocol_type_id = l_protocol_type_id_app_version)
                    AND (a.flow_type_id IS NULL
                    OR a.flow_type_id = l_flow_type_id_app_version)
                    AND (context = 'DataDomain' OR context = 'Step')
                ORDER BY a.id
            LOOP
                INSERT INTO config_model.orch_step_attrs (orch_step_id, attr_id, required, create_user, creation_date)
                VALUES (NEW.id, l_rec_row.id, l_rec_row.required, NEW.create_user, NEW.creation_date);

                FOR l_rec_row_aux IN
                    SELECT orch_step_app_instances.id
                    FROM config_model.orch_step_app_instances
                    WHERE orch_step_id = OLD.id
                LOOP
                    INSERT INTO config_model.orch_step_app_instance_attrs (orch_step_app_instance_id, attr_id, required)
                    VALUES (l_rec_row_aux.id, l_rec_row.id, l_rec_row.required);
                END LOOP;
            END LOOP;
        END IF;

        RETURN NEW;
    END;
    $function$
;

CREATE OR REPLACE FUNCTION config_model.f_biu_orch_steps()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    DECLARE
        l_data_domain_app INT;
        l_connection_app INT;
        l_protocol_type_id_connection INT;
        l_protocol_type_id_app_version INT;
        l_data_domain_protocol_type_name VARCHAR;
        l_app_name VARCHAR;
        l_count_status INT := 0;
        l_count_step_rows INT := 0;
    BEGIN
        SELECT av.app_id, a.name
        INTO l_data_domain_app, l_app_name
        FROM config_model.application_versions av, config_model.data_domain_app_versions ddav, config_model.applications a
        WHERE av.id = ddav.app_version_id AND ddav.id = NEW.data_domain_app_version_id
            AND a.id = av.app_id;

        SELECT c.app_id
        INTO l_connection_app
        FROM config_model.connections c
        WHERE c.id = NEW.connection_id;

        IF l_connection_app IS NOT NULL AND l_data_domain_app != l_connection_app THEN
            RAISE EXCEPTION 'You must choose the same Application for Data Domain and Connection data_domain_app: (%s), for connection (%s)', l_data_domain_app, l_connection_app;
            RETURN NULL;
        END IF;

        SELECT protocol_type_id
        INTO l_protocol_type_id_connection
        FROM config_model.connections c
        WHERE c.id = NEW.connection_id;

        SELECT protocol_type_id
        INTO l_protocol_type_id_app_version
        FROM config_model.data_domain_app_versions ddav
        WHERE ddav.id = NEW.data_domain_app_version_id;

        SELECT pt."name"
        INTO l_data_domain_protocol_type_name
        FROM config_model.protocol_type pt
        WHERE pt.id = l_protocol_type_id_app_version;

        IF (l_data_domain_protocol_type_name IN ('transportation', 'api') AND NEW.connection_id IS NULL) THEN
            RAISE EXCEPTION 'Error: transportation and API protocols need a connection.';
            RETURN NULL;
        END IF;

        IF l_protocol_type_id_connection IS NOT NULL AND l_protocol_type_id_app_version IS NOT NULL THEN
            IF l_protocol_type_id_connection != l_protocol_type_id_app_version AND l_data_domain_protocol_type_name != 'transportation' THEN
                RAISE EXCEPTION 'Error: different protocol type between connection and data domain app version';
                RETURN NULL;
            END IF;
        END IF;

        IF TG_OP = 'UPDATE' THEN
            IF NEW.update_user IS NULL OR NEW.update_user = '' THEN
                NEW.update_user := current_user;
            END IF;
            NEW.update_date := CURRENT_TIMESTAMP;

            IF NEW.status != OLD.status AND NEW.status != 'W' THEN
                UPDATE config_model.orch_step_app_instance_attrs
                SET status = NEW.status
                WHERE orch_step_app_instance_id IN (
                    SELECT id
                    FROM config_model.orch_step_app_instances
                    WHERE orch_step_id = OLD.id
                );

                UPDATE config_model.orch_step_app_instances
                SET status = NEW.status
                WHERE orch_step_id = OLD.id;

                UPDATE config_model.orch_step_attrs
                SET status = NEW.status
                WHERE orch_step_id = OLD.id;
            END IF;
        END IF;

        RETURN NEW;
    END;
    $function$
;


-- Table Triggers

CREATE TRIGGER trg_aui_orch_steps AFTER
INSERT
    OR
UPDATE
    ON
    config_model.orch_steps FOR EACH ROW EXECUTE FUNCTION config_model.f_aui_orch_steps();
CREATE TRIGGER trg_biu_orch_steps BEFORE
INSERT
    OR
UPDATE
    ON
    config_model.orch_steps FOR EACH ROW EXECUTE FUNCTION config_model.f_biu_orch_steps();


-- config_model.orch_steps foreign keys

ALTER TABLE config_model.orch_steps ADD CONSTRAINT orch_steps_connection_id_fkey FOREIGN KEY (connection_id) REFERENCES config_model.connections(id) ON DELETE CASCADE;
ALTER TABLE config_model.orch_steps ADD CONSTRAINT orch_steps_data_domain_app_version_id_fkey FOREIGN KEY (data_domain_app_version_id) REFERENCES config_model.data_domain_app_versions(id) ON DELETE CASCADE;
ALTER TABLE config_model.orch_steps ADD CONSTRAINT orch_steps_orch_id_fkey FOREIGN KEY (orch_id) REFERENCES config_model.orch_head(id) ON DELETE CASCADE;