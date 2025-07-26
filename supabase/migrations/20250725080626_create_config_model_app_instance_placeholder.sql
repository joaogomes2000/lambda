-- config_model.app_instance_placeholder definition

-- Drop table

-- DROP TABLE config_model.app_instance_placeholder;

CREATE TABLE config_model.app_instance_placeholder (
	id int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
	app_instance_id int4 NOT NULL,
	"name" varchar NOT NULL,
	value varchar NULL,
	status varchar(1) DEFAULT 'A'::character varying NOT NULL,
	create_user varchar DEFAULT CURRENT_USER NOT NULL,
	creation_date timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	update_user varchar NULL,
	update_date timestamp NULL,
	CONSTRAINT app_instance_placeholder_ck CHECK (((status)::text = ANY ((ARRAY['A'::character varying, 'I'::character varying])::text[]))),
	CONSTRAINT app_instance_placeholder_pk PRIMARY KEY (id)
);


-- config_model.app_instance_placeholder foreign keys

ALTER TABLE config_model.app_instance_placeholder ADD CONSTRAINT app_instance_placeholder_app_instance_id_fkey FOREIGN KEY (app_instance_id) REFERENCES config_model.application_instance(id) ON DELETE CASCADE;