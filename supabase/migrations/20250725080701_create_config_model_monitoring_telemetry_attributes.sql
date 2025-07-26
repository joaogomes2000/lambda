-- config_model.monitoring_telemetry_attributes definition

-- Drop table

-- DROP TABLE config_model.monitoring_telemetry_attributes;

CREATE TABLE config_model.monitoring_telemetry_attributes (
	span_id varchar(50) NOT NULL,
	attribute_key varchar(50) NOT NULL,
	attribute_value text NOT NULL,
	create_user varchar(50) DEFAULT CURRENT_USER NULL,
	created_date timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	update_user varchar(50) NULL,
	updated_date timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	CONSTRAINT monitoring_telemetry_attributes_pk PRIMARY KEY (span_id, attribute_key)
);
CREATE INDEX monitoring_telemetry_attributes_span_id ON config_model.monitoring_telemetry_attributes USING btree (span_id);


-- config_model.monitoring_telemetry_attributes foreign keys

ALTER TABLE config_model.monitoring_telemetry_attributes ADD CONSTRAINT monitoring_telemetry_attributes_span_id_fkey FOREIGN KEY (span_id) REFERENCES config_model.monitoring_telemetry(span_id) ON DELETE CASCADE;