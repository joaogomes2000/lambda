-- config_model.exec_transportation_control definition

-- Drop table

-- DROP TABLE config_model.exec_transportation_control;

CREATE TABLE config_model.exec_transportation_control (
	id int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
	correlation_id varchar NOT NULL,
	app_name varchar NOT NULL,
	app_instance_name varchar NULL,
	domain_name varchar NOT NULL,
	flow_type varchar NULL,
	transportation_compressed_file_name varchar NULL,
	transportation_file_name varchar NULL,
	transportation_file_size varchar NULL,
	after_transportation_file_name varchar NULL,
	error_msg text NULL,
	status varchar(1) DEFAULT 'N'::character varying NULL,
	insertion_timestamp timestamp DEFAULT CURRENT_TIMESTAMP NULL,
	duration_download_file float8 NULL,
	duration_upload_file float8 NULL,
	duration_after_transport_action float8 NULL,
	begin_proc_timestamp timestamp NULL,
	end_proc_timestamp timestamp NULL,
	create_user varchar DEFAULT CURRENT_USER NULL,
	creation_date timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	update_user varchar NULL,
	update_date timestamp NULL,
	CONSTRAINT exec_transportation_control_pk PRIMARY KEY (id),
	CONSTRAINT processing_status_check CHECK (((status)::text = ANY ((ARRAY['N'::character varying, 'H'::character varying, 'E'::character varying, 'P'::character varying, 'W'::character varying])::text[])))
);


-- config_model.exec_transportation_control foreign keys

ALTER TABLE config_model.exec_transportation_control ADD CONSTRAINT exec_transportation_control_ctrl_orch_fk FOREIGN KEY (correlation_id) REFERENCES config_model.ctrl_orch(correlation_id) ON DELETE CASCADE;