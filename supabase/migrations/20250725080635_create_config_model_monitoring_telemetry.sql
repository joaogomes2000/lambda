-- config_model.monitoring_telemetry definition

-- Drop table

-- DROP TABLE config_model.monitoring_telemetry;

CREATE TABLE config_model.monitoring_telemetry (
	trace_id varchar(50) NOT NULL,
	span_id varchar(50) NOT NULL,
	parent_span_id varchar(50) NULL,
	span_name varchar(255) NOT NULL,
	status_message text NULL,
	status_code varchar(50) DEFAULT 'OK'::character varying NOT NULL,
	start_time timestamp NOT NULL,
	end_time timestamp NOT NULL,
	create_user varchar(50) NULL,
	created_date timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	update_user varchar(50) NULL,
	updated_date timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	CONSTRAINT monitoring_telemetry_pkey PRIMARY KEY (trace_id, span_id),
	CONSTRAINT monitoring_telemetry_un UNIQUE (span_id)
);
CREATE INDEX monitoring_telemetry_parent_span_id_idx ON config_model.monitoring_telemetry USING btree (parent_span_id);
CREATE INDEX monitoring_telemetry_trace_id_idx ON config_model.monitoring_telemetry USING btree (trace_id);