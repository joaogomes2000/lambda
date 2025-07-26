-- config_model.data_domain_policy definition

-- Drop table

-- DROP TABLE config_model.data_domain_policy;

CREATE TABLE config_model.data_domain_policy (
	app_id int4 NOT NULL,
	data_domain_id int4 NULL,
	protocol_type_id int4 NULL,
	flow_type_id int4 NULL,
	code_error_id varchar NULL,
	policy_id int4 NULL,
	critical_ind varchar(50) NULL,
	context varchar(25) NULL,
	create_user varchar(50) DEFAULT CURRENT_USER NOT NULL,
	create_date timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	update_user varchar(50) NULL,
	updated_date timestamp NULL
);


-- config_model.data_domain_policy foreign keys

ALTER TABLE config_model.data_domain_policy ADD CONSTRAINT data_domain_policy_applications_fk FOREIGN KEY (app_id) REFERENCES config_model.applications(id);
ALTER TABLE config_model.data_domain_policy ADD CONSTRAINT data_domain_policy_data_domains_fk FOREIGN KEY (data_domain_id) REFERENCES config_model.data_domains(id);
ALTER TABLE config_model.data_domain_policy ADD CONSTRAINT data_domain_policy_flow_type_fk FOREIGN KEY (flow_type_id) REFERENCES config_model.flow_type(id);
ALTER TABLE config_model.data_domain_policy ADD CONSTRAINT data_domain_policy_monitoring_policies_fk FOREIGN KEY (policy_id) REFERENCES config_model.monitoring_policies(id);
ALTER TABLE config_model.data_domain_policy ADD CONSTRAINT data_domain_policy_protocol_type_fk FOREIGN KEY (protocol_type_id) REFERENCES config_model.protocol_type(id);