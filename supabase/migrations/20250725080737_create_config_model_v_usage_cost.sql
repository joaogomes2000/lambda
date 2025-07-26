    CREATE OR REPLACE VIEW config_model.v_usage_cost AS
    SELECT correlation_id AS execution_id,
           date,
           sum(operations_num) AS total_operations,
           sum(total_transactions) AS total_transactions,
           to_char(sum(total_exec_time), 'HH24:MI:SS'::text) AS total_exec_time
    FROM (
        SELECT efc.correlation_id,
               to_char(efc.insertion_timestamp, 'YYYY-MM-DD'::text) AS date,
               count(1) AS operations_num,
               sum(COALESCE(efc.file_num_lines, 0)) AS total_transactions,
               sum(efc.end_proc_timestamp - efc.begin_proc_timestamp) AS total_exec_time
        FROM config_model.exec_file_control efc
        GROUP BY efc.correlation_id, to_char(efc.insertion_timestamp, 'YYYY-MM-DD'::text)

        UNION

        SELECT eac.correlation_id,
               to_char(eac.insertion_timestamp, 'YYYY-MM-DD'::text) AS date,
               count(1) AS operations_num,
               sum(COALESCE(eac.lines_processed, 0)) AS total_transactions,
               sum(eac.end_proc_timestamp - eac.begin_proc_timestamp) AS total_exec_time
        FROM config_model.exec_api_control eac
        GROUP BY eac.correlation_id, to_char(eac.insertion_timestamp, 'YYYY-MM-DD'::text)

        UNION

        SELECT edc.correlation_id,
               to_char(edc.insertion_timestamp, 'YYYY-MM-DD'::text) AS date,
               count(1) AS operations_num,
               sum(COALESCE(edc.lines_processed, 0)) AS total_transactions,
               sum(edc.end_proc_timestamp - edc.begin_proc_timestamp) AS total_exec_time
        FROM config_model.exec_db_control edc
        GROUP BY edc.correlation_id, to_char(edc.insertion_timestamp, 'YYYY-MM-DD'::text)

        UNION

        SELECT esc.correlation_id,
               to_char(esc.creation_date, 'YYYY-MM-DD'::text) AS date,
               count(1) AS operations_num,
               0 AS total_transactions,
               sum(esc.end_proc_timestamp - esc.begin_proc_timestamp) AS total_exec_time
        FROM config_model.exec_sync_control esc
        GROUP BY esc.correlation_id, to_char(esc.creation_date, 'YYYY-MM-DD'::text)

        UNION

        SELECT etc.correlation_id,
               to_char(etc.insertion_timestamp, 'YYYY-MM-DD'::text) AS date,
               count(1) AS operations_num,
               0 AS total_transactions,
               sum(etc.end_proc_timestamp - etc.begin_proc_timestamp) AS total_exec_time
        FROM config_model.exec_transportation_control etc
        GROUP BY etc.correlation_id, to_char(etc.insertion_timestamp, 'YYYY-MM-DD'::text)

        UNION

        SELECT eic.correlation_id,
               to_char(eic.creation_date, 'YYYY-MM-DD'::text) AS date,
               count(1) AS operations_num,
               0 AS total_transactions,
               sum(eic.end_proc_timestamp - eic.begin_proc_timestamp) AS total_exec_time
        FROM config_model.exec_internal_control eic
        GROUP BY eic.correlation_id, to_char(eic.creation_date, 'YYYY-MM-DD'::text)
    ) unnamed_subquery
    GROUP BY correlation_id, date;