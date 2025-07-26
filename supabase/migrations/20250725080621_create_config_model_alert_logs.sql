-- config_model.alert_logs definition

-- Drop table

-- DROP TABLE config_model.alert_logs;

CREATE TABLE config_model.alert_logs (
	id int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
	alert_rule varchar NULL,
	severity varchar NULL,
	context varchar NULL,
	create_user varchar DEFAULT CURRENT_USER NOT NULL,
	create_date timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	update_user varchar NULL,
	update_date timestamp NULL,
	CONSTRAINT alert_logs_pkey PRIMARY KEY (id)
);