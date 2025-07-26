-- config_model.sequences_ctrl definition

-- Drop table

-- DROP TABLE config_model.sequences_ctrl;

CREATE TABLE config_model.sequences_ctrl (
	id int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
	app_version_id int4 NOT NULL,
	app_instance_id int4 NULL,
	data_domain_id int4 NOT NULL,
	protocol_type_id int4 NOT NULL,
	"sequence" int8 DEFAULT 0 NOT NULL,
	status varchar(1) DEFAULT 'A'::character varying NOT NULL,
	create_user varchar DEFAULT CURRENT_USER NOT NULL,
	creation_date timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	update_user varchar NULL,
	update_date timestamp NULL,
	CONSTRAINT sequences_ctrl_ck CHECK (((status)::text = ANY ((ARRAY['A'::character varying, 'I'::character varying])::text[]))),
	CONSTRAINT sequences_ctrl_pk PRIMARY KEY (id)
);


-- config_model.sequences_ctrl foreign keys

ALTER TABLE config_model.sequences_ctrl ADD CONSTRAINT sequences_ctrl_app_instance_id_fkey FOREIGN KEY (app_instance_id) REFERENCES config_model.application_instance(id) ON DELETE CASCADE;
ALTER TABLE config_model.sequences_ctrl ADD CONSTRAINT sequences_ctrl_app_version_id_fkey FOREIGN KEY (app_version_id) REFERENCES config_model.application_versions(id) ON DELETE CASCADE;
ALTER TABLE config_model.sequences_ctrl ADD CONSTRAINT sequences_ctrl_data_domain_id_fkey FOREIGN KEY (data_domain_id) REFERENCES config_model.data_domains(id) ON DELETE CASCADE;
ALTER TABLE config_model.sequences_ctrl ADD CONSTRAINT sequences_ctrl_protocol_type_id_fkey FOREIGN KEY (protocol_type_id) REFERENCES config_model.protocol_type(id) ON DELETE CASCADE;