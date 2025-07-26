CREATE OR REPLACE VIEW config_model.fe_view_operations_monitoring_dtls_head AS
    SELECT DISTINCT co.correlation_id AS execution_id,
           co.orch_id AS orchestration_id,
           cos2.orch_step_id AS step_id,
           to_char(CURRENT_TIMESTAMP, 'YYYY-MM-DD"T"HH24:MI:SS'::text) AS operation_date,
           os.name AS step_name,
           pt.name AS protocol,
           CASE
               WHEN cos2.status::text = 'R'::text THEN 'Recovered'::text
               WHEN cos2.status::text = 'E'::text THEN 'Error'::text
               WHEN EXISTS (
                   SELECT 1 FROM config_model.fe_view_operations_monitoring_dtls_file f
                   WHERE f.execution_id::text = co.correlation_id::text
                   AND f.business_object::text = dd.domain_name::text
                   AND f.status = 'Error'::text
               ) THEN 'Error'::text
               WHEN EXISTS (
                   SELECT 1 FROM config_model.fe_view_operations_monitoring_dtls_db db
                   WHERE db.execution_id::text = co.correlation_id::text
                   AND db.business_object::text = dd.domain_name::text
                   AND db.status = 'Error'::text
               ) THEN 'Error'::text
               WHEN EXISTS (
                   SELECT 1 FROM config_model.fe_view_operations_monitoring_dtls_api api
                   WHERE api.execution_id::text = co.correlation_id::text
                   AND api.business_object::text = dd.domain_name::text
                   AND api.status = 'Error'::text
               ) THEN 'Error'::text
               WHEN EXISTS (
                   SELECT 1 FROM config_model.fe_view_operations_monitoring_dtls_file f
                   WHERE f.execution_id::text = co.correlation_id::text
                   AND f.business_object::text = dd.domain_name::text
                   AND f.status = 'Warning'::text
               ) THEN 'Warning'::text
               WHEN EXISTS (
                   SELECT 1 FROM config_model.fe_view_operations_monitoring_dtls_db db
                   WHERE db.execution_id::text = co.correlation_id::text
                   AND db.business_object::text = dd.domain_name::text
                   AND db.status = 'Warning'::text
               ) THEN 'Warning'::text
               WHEN EXISTS (
                   SELECT 1 FROM config_model.fe_view_operations_monitoring_dtls_api api
                   WHERE api.execution_id::text = co.correlation_id::text
                   AND api.business_object::text = dd.domain_name::text
                   AND api.status = 'Warning'::text
               ) THEN 'Warning'::text
               WHEN cos2.status::text = 'P'::text THEN 'Processed'::text
               WHEN cos2.status::text = 'W'::text THEN 'Processing'::text
               WHEN cos2.status::text = 'Q'::text THEN 'Processing'::text
               ELSE NULL::text
           END AS step_status,
           a.name AS app_name,
           a.description AS app_description,
           dd.domain_name AS business_object,
           ft.name AS direction,
           to_char(cos2.end_timestamp - cos2.begin_timestamp, 'HH24:MI:SS'::text)::interval AS execution_time,
           cos2.msg AS message
    FROM config_model.ctrl_orch co
         JOIN config_model.ctrl_orch_step cos2
           ON cos2.orch_id = co.orch_id
           AND cos2.correlation_id::text = co.correlation_id::text
         JOIN config_model.orch_steps os
           ON cos2.orch_step_id = os.id
           AND cos2.orch_id = os.orch_id
         JOIN config_model.data_domain_app_versions ddav
           ON os.data_domain_app_version_id = ddav.id
         JOIN config_model.protocol_type pt
           ON ddav.protocol_type_id = pt.id
         JOIN config_model.application_versions av
           ON ddav.app_version_id = av.id
         JOIN config_model.applications a
           ON av.app_id = a.id
         JOIN config_model.data_domains dd
           ON ddav.data_domain_id = dd.id
         JOIN config_model.flow_type ft
           ON ddav.flow_type_id = ft.id;