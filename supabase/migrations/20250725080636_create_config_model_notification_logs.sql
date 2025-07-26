-- config_model.notification_logs definition

-- Drop table

-- DROP TABLE config_model.notification_logs;

CREATE TABLE config_model.notification_logs (
	id int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
	user_email varchar NULL,
	channel_name varchar NULL,
	subject varchar NULL,
	description text NULL,
	error_message text NULL,
	additional_info json NULL,
	status varchar NULL,
	create_user varchar DEFAULT CURRENT_USER NOT NULL,
	create_date timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	update_user varchar NULL,
	update_date timestamp NULL,
	CONSTRAINT notification_logs_pkey PRIMARY KEY (id)
);