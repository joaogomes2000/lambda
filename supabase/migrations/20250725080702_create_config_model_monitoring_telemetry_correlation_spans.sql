-- config_model.monitoring_telemetry_correlation_spans definition

-- Drop table

-- DROP TABLE config_model.monitoring_telemetry_correlation_spans;

CREATE TABLE config_model.monitoring_telemetry_correlation_spans (
	correlation_manager_id varchar NOT NULL,
	correlation_id varchar NOT NULL,
	trace_id varchar(50) NOT NULL,
	span_id varchar(50) NOT NULL,
	orch_id int4 NULL,
	orch_step_id int4 NULL,
	create_user varchar(50) DEFAULT CURRENT_USER NULL,
	created_date timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	update_user varchar(50) NULL,
	updated_date timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	CONSTRAINT monitoring_telemetry_correlation_spans_pkey PRIMARY KEY (correlation_manager_id, correlation_id, trace_id, span_id)
);


-- config_model.monitoring_telemetry_correlation_spans foreign keys

ALTER TABLE config_model.monitoring_telemetry_correlation_spans ADD CONSTRAINT monitoring_telemetry_correlation_spans_orch_id_fkey FOREIGN KEY (orch_id) REFERENCES config_model.orch_head(id) ON DELETE CASCADE;
ALTER TABLE config_model.monitoring_telemetry_correlation_spans ADD CONSTRAINT monitoring_telemetry_correlation_spans_orch_step_id_fkey FOREIGN KEY (orch_step_id) REFERENCES config_model.orch_steps(id) ON DELETE CASCADE;
ALTER TABLE config_model.monitoring_telemetry_correlation_spans ADD CONSTRAINT monitoring_telemetry_correlation_spans_span_id_fkey FOREIGN KEY (span_id) REFERENCES config_model.monitoring_telemetry(span_id) ON DELETE CASCADE;