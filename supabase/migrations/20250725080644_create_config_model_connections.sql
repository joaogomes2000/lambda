-- config_model.connections definition

-- Drop table

-- DROP TABLE config_model.connections;

CREATE TABLE config_model.connections (
	id int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
	app_id int4 NOT NULL,
	protocol_type_id int4 NOT NULL,
	description varchar NOT NULL,
	product_definition bool DEFAULT false NULL,
	status varchar(1) DEFAULT 'A'::character varying NOT NULL,
	reference_id int4 NULL,
	mark_as_deleted bool DEFAULT false NULL,
	create_user varchar DEFAULT CURRENT_USER NOT NULL,
	creation_date timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	update_user varchar NULL,
	update_date timestamp NULL,
	CONSTRAINT connections_ck CHECK (((status)::text = ANY ((ARRAY['A'::character varying, 'I'::character varying, 'W'::character varying])::text[]))),
	CONSTRAINT connections_pk PRIMARY KEY (id)
);

-- create function

CREATE OR REPLACE FUNCTION config_model.f_aui_connections()
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
                WHERE (protocol_type_id = NEW.protocol_type_id OR protocol_type_id IS NULL)
                      AND context = 'Connection'
                ORDER BY id
            LOOP
                INSERT INTO config_model.connection_attrs(connection_id, attr_id, required, create_user, creation_date)
                VALUES (NEW.id, l_rec_row.id, l_rec_row.required, NEW.create_user, NEW.creation_date);
            END LOOP;
        END IF;

        IF TG_OP = 'UPDATE' THEN
            IF NEW.protocol_type_id != OLD.protocol_type_id THEN
                DELETE FROM config_model.connection_attrs WHERE connection_id = OLD.id;

                FOR l_rec_row IN
                    SELECT id, required
                    FROM config_model.attributes
                    WHERE (protocol_type_id = NEW.protocol_type_id OR protocol_type_id IS NULL)
                          AND context = 'Connection'
                    ORDER BY id
                LOOP
                    INSERT INTO config_model.connection_attrs(connection_id, attr_id, required, create_user, creation_date)
                    VALUES (NEW.id, l_rec_row.id, l_rec_row.required, NEW.create_user, NEW.creation_date);
                END LOOP;
            END IF;
        END IF;

        RETURN NEW;
    END;
    $function$
;

-- DROP FUNCTION config_model.f_biu_connections();

CREATE OR REPLACE FUNCTION config_model.f_biu_connections()
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
                UPDATE config_model.connection_attrs
                SET status = NEW.status
                WHERE connection_id = OLD.id;

                UPDATE config_model.orch_steps
                SET status = NEW.status
                WHERE connection_id = OLD.id;
            END IF;
        ELSIF TG_OP = 'INSERT' AND NEW.description IS NULL THEN
            SELECT description
            INTO l_app_name
            FROM config_model.applications a
            WHERE a.id = NEW.app_id;

            SELECT description
            INTO l_protocol_name
            FROM config_model.protocol_type pt
            WHERE pt.id = NEW.protocol_type_id;

            NEW.description := l_app_name || ' ' || l_protocol_name;
        END IF;
        RETURN NEW;
    END;
    $function$
;


-- Table Triggers

CREATE TRIGGER trg_aui_connections AFTER
INSERT
    OR
UPDATE
    ON
    config_model.connections FOR EACH ROW EXECUTE FUNCTION config_model.f_aui_connections();
CREATE TRIGGER trg_biu_connections BEFORE
INSERT
    OR
UPDATE
    ON
    config_model.connections FOR EACH ROW EXECUTE FUNCTION config_model.f_biu_connections();


-- config_model.connections foreign keys

ALTER TABLE config_model.connections ADD CONSTRAINT connections_app_id_fkey FOREIGN KEY (app_id) REFERENCES config_model.applications(id) ON DELETE CASCADE;
ALTER TABLE config_model.connections ADD CONSTRAINT connections_protocol_type_id_fkey FOREIGN KEY (protocol_type_id) REFERENCES config_model.protocol_type(id) ON DELETE CASCADE;