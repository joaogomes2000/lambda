-- config_model.monitoring_error_catalogue definition

-- Drop table

-- DROP TABLE config_model.monitoring_error_catalogue;

CREATE TABLE config_model.monitoring_error_catalogue (
	id int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
	"language" varchar(50) NOT NULL,
	message_pattern text NOT NULL,
	translated_message text NOT NULL,
	active varchar(1) DEFAULT 'A'::character varying NOT NULL,
	create_user varchar(50) NULL,
	created_date timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	update_user varchar(50) NULL,
	updated_date timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	CONSTRAINT monitoring_error_catalogue_ck CHECK (((active)::text = ANY ((ARRAY['A'::character varying, 'I'::character varying])::text[]))),
	CONSTRAINT monitoring_error_catalogue_pkey PRIMARY KEY (id)
);