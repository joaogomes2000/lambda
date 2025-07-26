CREATE OR REPLACE VIEW config_model.fe_view_operations_monitoring_dtls
AS SELECT execution_id,
    orchestration_id,
    step_id,
    operation_date,
    step_name,
    protocol,
        CASE
            WHEN status::text = 'P'::text THEN 'Processed'::text
            WHEN status::text = 'W'::text THEN 'Warning'::text
            WHEN status::text = 'R'::text THEN 'Recovered'::text
            WHEN status::text = 'Q'::text THEN 'Processing'::text
            WHEN status::text = 'E'::text THEN 'Error'::text
            ELSE NULL::text
        END AS step_status,
    application,
    business_object,
    direction,
    operation_object,
    size,
    records,
    processed,
    discarded,
    error,
    duration,
        CASE
            WHEN status::text = 'P'::text THEN 'Processed'::text
            WHEN status::text = 'W'::text THEN 'Processing'::text
            WHEN status::text = 'R'::text THEN 'Recovered'::text
            WHEN status::text = 'Q'::text THEN 'Processing'::text
            WHEN status::text = 'E'::text THEN 'Error'::text
            ELSE NULL::text
        END AS status
   FROM ( SELECT DISTINCT co.correlation_id AS execution_id,
            co.orch_id AS orchestration_id,
            cos2.orch_step_id AS step_id,
            to_char(CURRENT_TIMESTAMP, 'YYYY-MM-DD"T"HH24:MI:SS'::text) AS operation_date,
            os.name AS step_name,
            pt.name AS protocol,
            cos2.status AS step_status,
            a.description AS application,
            dd.domain_name AS business_object,
            ft.name AS direction,
                CASE
                    WHEN lower(pt.name::text) = 'db'::text THEN edc.core_table
                    WHEN lower(pt.name::text) = 'api'::text THEN eac.url
                    WHEN lower(pt.name::text) = 'file'::text THEN efc.filename
                    WHEN lower(pt.name::text) = 'transportation'::text THEN etc.transportation_compressed_file_name
                    WHEN lower(pt.name::text) = 'internal'::text THEN eic.sql_execution_query::character varying
                    WHEN lower(pt.name::text) = 'sync'::text THEN esc.core_table
                    ELSE NULL::character varying
                END AS operation_object,
                CASE
                    WHEN lower(pt.name::text) = 'file'::text THEN efc.file_size
                    WHEN lower(pt.name::text) = 'transportation'::text THEN etc.transportation_file_size
                    ELSE NULL::character varying
                END AS size,
                CASE
                    WHEN lower(pt.name::text) = 'file'::text THEN efc.file_num_lines
                    WHEN lower(pt.name::text) = 'db'::text THEN edc.lines_processed + edc.lines_discarded + edc.lines_errors
                    WHEN lower(pt.name::text) = 'api'::text THEN eac.lines_processed + eac.lines_discarded + eac.lines_errors
                    ELSE NULL::integer
                END AS records,
                CASE
                    WHEN lower(pt.name::text) = 'db'::text THEN edc.lines_processed
                    WHEN lower(pt.name::text) = 'api'::text THEN eac.lines_processed
                    WHEN lower(pt.name::text) = 'file'::text THEN efc.lines_processed
                    ELSE NULL::integer
                END AS processed,
                CASE
                    WHEN lower(pt.name::text) = 'db'::text THEN edc.lines_discarded
                    WHEN lower(pt.name::text) = 'api'::text THEN eac.lines_discarded
                    WHEN lower(pt.name::text) = 'file'::text THEN efc.lines_discarded
                    ELSE NULL::integer
                END AS discarded,
                CASE
                    WHEN lower(pt.name::text) = 'db'::text THEN edc.lines_errors
                    WHEN lower(pt.name::text) = 'api'::text THEN eac.lines_errors
                    WHEN lower(pt.name::text) = 'file'::text THEN efc.lines_errors
                    ELSE NULL::integer
                END AS error,
                CASE
                    WHEN lower(pt.name::text) = 'db'::text THEN edc.end_proc_timestamp - edc.begin_proc_timestamp
                    WHEN lower(pt.name::text) = 'api'::text THEN eac.end_proc_timestamp - eac.begin_proc_timestamp
                    WHEN lower(pt.name::text) = 'file'::text THEN efc.end_proc_timestamp - efc.begin_proc_timestamp
                    WHEN lower(pt.name::text) = 'transportation'::text THEN etc.end_proc_timestamp - etc.begin_proc_timestamp
                    WHEN lower(pt.name::text) = 'internal'::text THEN eic.end_proc_timestamp - eic.begin_proc_timestamp
                    WHEN lower(pt.name::text) = 'sync'::text THEN esc.end_proc_timestamp - esc.begin_proc_timestamp
                    ELSE NULL::interval
                END AS duration,
                CASE
                    WHEN lower(pt.name::text) = 'db'::text THEN edc.status
                    WHEN lower(pt.name::text) = 'api'::text THEN eac.status
                    WHEN lower(pt.name::text) = 'file'::text THEN efc.status
                    WHEN lower(pt.name::text) = 'transportation'::text THEN etc.status
                    WHEN lower(pt.name::text) = 'internal'::text THEN eic.status
                    WHEN lower(pt.name::text) = 'sync'::text THEN esc.status
                    ELSE ''::character varying
                END AS status
           FROM config_model.ctrl_orch co
             JOIN config_model.ctrl_orch_step cos2 ON cos2.orch_id = co.orch_id AND cos2.correlation_id::text = co.correlation_id::text
             JOIN config_model.orch_steps os ON cos2.orch_step_id = os.id AND cos2.orch_id = os.orch_id
             JOIN config_model.data_domain_app_versions ddav ON os.data_domain_app_version_id = ddav.id
             JOIN config_model.protocol_type pt ON ddav.protocol_type_id = pt.id
             JOIN config_model.application_versions av ON ddav.app_version_id = av.id
             JOIN config_model.applications a ON av.app_id = a.id
             JOIN config_model.data_domains dd ON ddav.data_domain_id = dd.id
             JOIN config_model.flow_type ft ON ddav.flow_type_id = ft.id
             LEFT JOIN config_model.exec_file_control efc ON cos2.correlation_id::text = efc.correlation_id::text AND efc.domain_name::text = dd.domain_name::text
             LEFT JOIN config_model.exec_transportation_control etc ON cos2.correlation_id::text = etc.correlation_id::text AND etc.domain_name::text = dd.domain_name::text
             LEFT JOIN config_model.exec_internal_control eic ON cos2.correlation_id::text = eic.correlation_id::text
             LEFT JOIN config_model.exec_sync_control esc ON cos2.correlation_id::text = esc.correlation_id::text AND esc.domain_name::text = dd.domain_name::text
             LEFT JOIN config_model.exec_db_control edc ON cos2.correlation_id::text = edc.correlation_id::text AND edc.domain_name::text = dd.domain_name::text
             LEFT JOIN config_model.exec_api_control eac ON cos2.correlation_id::text = eac.correlation_id::text AND eac.domain_name::text = dd.domain_name::text) unnamed_subquery;
