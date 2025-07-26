-- config_model.templates_config definition

-- Drop table

-- DROP TABLE config_model.templates_config;

CREATE TABLE config_model.templates_config (
	id int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
	alert_rule varchar NULL,
	severity varchar NULL,
	context varchar NULL,
	error_code_id varchar NULL,
	channel_id int4 NULL,
	template_title varchar NOT NULL,
	template_body varchar NOT NULL,
	template_required_fields varchar NULL,
	status varchar(1) DEFAULT 'A'::character varying NOT NULL,
	mark_as_deleted bool DEFAULT false NULL,
	create_user varchar DEFAULT CURRENT_USER NOT NULL,
	create_date timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	update_user varchar NULL,
	update_date timestamp NULL,
	CONSTRAINT templates_config_pkey PRIMARY KEY (id)
);


-- config_model.templates_config foreign keys

ALTER TABLE config_model.templates_config ADD CONSTRAINT templates_config_channel_id_fkey FOREIGN KEY (channel_id) REFERENCES config_model.channel_config(id) ON DELETE CASCADE;