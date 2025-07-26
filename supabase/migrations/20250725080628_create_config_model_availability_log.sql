-- config_model.availability_log definition

-- Drop table

-- DROP TABLE config_model.availability_log;

CREATE TABLE config_model.availability_log (
	id varchar NOT NULL,
	alert_rule varchar NOT NULL,
	severity varchar NOT NULL,
	monitor_condition varchar NOT NULL,
	resource_type varchar NOT NULL,
	component_name varchar NOT NULL,
	fired_date_time timestamp NOT NULL,
	resolved_date_time timestamp NULL,
	alert_context text NULL,
	create_user varchar DEFAULT CURRENT_USER NOT NULL,
	creation_date timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	update_user varchar NULL,
	update_date timestamp NULL
);