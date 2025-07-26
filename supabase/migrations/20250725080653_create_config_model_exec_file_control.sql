-- config_model.exec_file_control definition

-- Drop table

-- DROP TABLE config_model.exec_file_control;

CREATE TABLE config_model.exec_file_control (
	id int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
	correlation_id varchar NOT NULL,
	filename varchar NOT NULL,
	blob_creation_date timestamp NULL,
	app_name varchar NOT NULL,
	app_instance_name varchar NULL,
	domain_name varchar NOT NULL,
	flow_type varchar NULL,
	file_entity varchar NOT NULL,
	file_date date NULL,
	file_seq varchar NULL,
	file_size varchar NULL,
	file_num_lines int4 NULL,
	ignore_file varchar(1) DEFAULT 'N'::character varying NULL,
	lines_processed int4 NULL,
	lines_discarded int4 NULL,
	lines_errors int4 NULL,
	error_msg text NULL,
	status varchar(1) DEFAULT 'N'::character varying NULL,
	insertion_timestamp timestamp DEFAULT CURRENT_TIMESTAMP NULL,
	duration_download_file float8 NULL,
	duration_read_file float8 NULL,
	duration_check_file float8 NULL,
	duration_load_to_db float8 NULL,
	duration_create_file float8 NULL,
	duration_upload_file float8 NULL,
	duration_upload_file_errors float8 NULL,
	duration_upload_file_discarded float8 NULL,
	begin_proc_timestamp timestamp NULL,
	end_proc_timestamp timestamp NULL,
	create_user varchar DEFAULT CURRENT_USER NULL,
	creation_date timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
	update_user varchar NULL,
	update_date timestamp NULL,
	filename_mapped text NULL,
	CONSTRAINT exec_file_control_pk PRIMARY KEY (id),
	CONSTRAINT ignore_file_check CHECK (((ignore_file)::text = ANY ((ARRAY['Y'::character varying, 'N'::character varying])::text[]))),
	CONSTRAINT processing_status_check CHECK (((status)::text = ANY ((ARRAY['N'::character varying, 'H'::character varying, 'E'::character varying, 'P'::character varying, 'W'::character varying, 'M'::character varying])::text[])))
);

-- create function

CREATE OR REPLACE FUNCTION config_model.f_sync_exec_file_control()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_status_id int := 0;
	v_data_flow_id int := 0;
BEGIN
  if TG_OP = 'INSERT' then
		SELECT s.id INTO v_status_id
		FROM public.status s
		WHERE s.description = (
		    CASE NEW.status
		        WHEN 'Q' THEN 'Processing'
		        WHEN 'W' THEN 'Warning'
		        WHEN 'E' THEN 'Error'
		        WHEN 'P' THEN 'Processed'
		        WHEN 'R' THEN 'Recovered'
		        ELSE NULL
		    END
		);

	    SELECT id into v_data_flow_id FROM public.monitoring_dataflow mdf where mdf.execution_flow_id = new.correlation_id;

       insert into public.monitoring_dataflow_files (id, file_name, file_size, row_count, row_discarded, row_error, row_processed, statusid, dataflow_id)
	   values (new.id, new.filename, new.file_size, new.file_num_lines, new.lines_discarded, new.lines_errors, new.lines_processed, v_status_id, v_data_flow_id);

	elsif TG_OP = 'UPDATE' then
	 SELECT s.id INTO v_status_id
		FROM public.status s
		WHERE s.description = (
		    CASE NEW.status
		        WHEN 'Q' THEN 'Processing'
		        WHEN 'W' THEN 'Warning'
		        WHEN 'E' THEN 'Error'
		        WHEN 'P' THEN 'Processed'
		        WHEN 'R' THEN 'Recovered'
		        ELSE NULL
		    END
		);

	 update public.monitoring_dataflow_files
	 	  set statusid = v_status_id,
			  file_name = new.filename,
			  file_size = new.file_size,
			  row_count = new.file_num_lines,
			  row_discarded = new.lines_discarded,
			  row_error = new.lines_errors,
			  row_processed = new.lines_processed
        where id = new.id;

  	elsif TG_OP = 'DELETE' then
       delete from public.monitoring_dataflow_files
        where id = old.id;
  end if;
  RETURN NEW;
END;
$function$
;


-- Table Triggers

CREATE TRIGGER trg_sync_exec_file_control AFTER
INSERT
    OR
DELETE
    OR
UPDATE
    ON
    config_model.exec_file_control FOR EACH ROW EXECUTE FUNCTION config_model.f_sync_exec_file_control();


-- config_model.exec_file_control foreign keys

ALTER TABLE config_model.exec_file_control ADD CONSTRAINT exec_file_control_ctrl_orch_fk FOREIGN KEY (correlation_id) REFERENCES config_model.ctrl_orch(correlation_id) ON DELETE CASCADE;