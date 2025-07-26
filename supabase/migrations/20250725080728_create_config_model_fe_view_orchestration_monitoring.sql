CREATE OR REPLACE VIEW config_model.fe_view_orchestration_monitoring AS
    SELECT co.correlation_id AS execution_id,
           oh.id AS orchestration_id,
           oh.name,
           string_agg(DISTINCT a.description::text, ', '::text) AS application,
           string_agg(DISTINCT pt.name::text, ', '::text) AS protocol,
           CASE
               WHEN EXISTS (
                   SELECT 1 FROM config_model.fe_view_operations_monitoring_dtls_head oh_1
                   WHERE oh_1.execution_id::text = co.correlation_id::text
                   AND oh_1.step_status = 'Warning'::text
               ) THEN 'Warning'::text
               WHEN co.status::text = 'P'::text THEN 'Processed'::text
               WHEN co.status::text = 'W'::text THEN 'Processing'::text
               WHEN co.status::text = 'R'::text THEN 'Recovered'::text
               WHEN co.status::text = 'Q'::text THEN 'Processing'::text
               WHEN co.status::text = 'E'::text THEN 'Error'::text
               ELSE NULL::text
           END AS status,
           co.msg AS message,
           to_char(co.begin_timestamp, 'YYYY-MM-DD"T"HH24:MI:SS'::text) AS begin,
           to_char(co.end_timestamp, 'YYYY-MM-DD"T"HH24:MI:SS'::text) AS "end",
           to_char(co.end_timestamp - co.begin_timestamp, 'HH24:MI:SS'::text) AS timeelapsed
    FROM config_model.orch_head oh
         JOIN config_model.ctrl_orch co ON oh.id = co.orch_id
         JOIN (
             SELECT ost.id, ost.orch_id, ost.orch_step, ost.name, ost.data_domain_app_version_id, ost.connection_id,
                    ost.parallel_ind, ost.status, ost.create_user, ost.creation_date, ost.update_user, ost.update_date
             FROM config_model.orch_steps ost
             ORDER BY ost.orch_id, ost.orch_step
         ) os ON oh.id = os.orch_id
         JOIN config_model.data_domain_app_versions ddav ON os.data_domain_app_version_id = ddav.id
         JOIN config_model.application_versions av ON av.id = ddav.app_version_id
         JOIN config_model.applications a ON av.app_id = a.id
         JOIN config_model.protocol_type pt ON ddav.protocol_type_id = pt.id
    WHERE pt.name::text <> ALL (ARRAY['sync'::character varying::text, 'internal'::character varying::text, 'transportation'::character varying::text])
    GROUP BY co.correlation_id, oh.id, oh.name, co.status, co.msg;