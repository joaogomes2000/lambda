-- config_model.monitoring_errors definition

-- Drop table

-- DROP TABLE config_model.monitoring_errors;

CREATE TABLE config_model.monitoring_errors (
	error_id int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
	span_id varchar(50) NOT NULL,
	error_code varchar(255) NULL,
	error_message text NOT NULL,
	status varchar(50) DEFAULT 'N'::character varying NOT NULL,
	error_timestamp timestamp NOT NULL,
	id int4 NULL,
	"language" varchar(50) NULL,
	message_pattern varchar(50) NULL,
	translated_message varchar(128) NULL,
	active varchar(50) NULL,
	create_user varchar(50) DEFAULT CURRENT_USER NULL,
	created_date timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	update_user varchar(50) NULL,
	updated_date timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	CONSTRAINT monitoring_errors_pkey PRIMARY KEY (error_id)
);


-- config_model.monitoring_errors foreign keys

ALTER TABLE config_model.monitoring_errors ADD CONSTRAINT monitoring_errors_span_id_fkey FOREIGN KEY (span_id) REFERENCES config_model.monitoring_telemetry(span_id) ON DELETE CASCADE;