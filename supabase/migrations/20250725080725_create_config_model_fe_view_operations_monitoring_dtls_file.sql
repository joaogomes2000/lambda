CREATE OR REPLACE VIEW config_model.fe_view_operations_monitoring_dtls_file AS
    SELECT correlation_id AS execution_id,
           domain_name AS business_object,
           filename AS operation_object,
           file_size AS size,
           file_num_lines AS records,
           lines_processed AS processed,
           lines_discarded AS discarded,
           lines_errors AS error,
           to_char(end_proc_timestamp - begin_proc_timestamp, 'HH24:MI:SS'::text) AS duration,
           CASE
               WHEN status::text = 'P'::text THEN 'Processed'::text
               WHEN status::text = 'W'::text THEN 'Warning'::text
               WHEN status::text = 'R'::text THEN 'Recovered'::text
               WHEN status::text = 'Q'::text THEN 'Waiting'::text
               WHEN status::text = 'E'::text THEN 'Error'::text
               WHEN status::text = 'H'::text THEN 'Processing'::text
               ELSE NULL::text
           END AS status
    FROM config_model.exec_file_control efc;