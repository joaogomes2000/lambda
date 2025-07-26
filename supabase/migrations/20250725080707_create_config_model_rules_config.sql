-- config_model.rules_config definition

-- Drop table

-- DROP TABLE config_model.rules_config;

CREATE TABLE config_model.rules_config (
	id int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
	channel_id int4 NULL,
	severity varchar NULL,
	context varchar NULL,
	"target" varchar NOT NULL,
	status varchar(1) DEFAULT 'A'::character varying NOT NULL,
	create_user varchar DEFAULT CURRENT_USER NOT NULL,
	create_date timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	update_user varchar NULL,
	update_date timestamp NULL,
	CONSTRAINT rules_config_pkey PRIMARY KEY (id)
);


-- config_model.rules_config foreign keys

ALTER TABLE config_model.rules_config ADD CONSTRAINT rules_config_channel_id_fkey FOREIGN KEY (channel_id) REFERENCES config_model.channel_config(id) ON DELETE CASCADE;