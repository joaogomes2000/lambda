    CREATE OR REPLACE VIEW config_model.fe_view_operation_flow_dtls AS
    SELECT s.id,
           s.orch_id AS flow_id,
           s.frequency_mask AS cron_expression,
           to_char(max(co.begin_timestamp), 'YYYY-MM-DD"T"HH24:MI:SS'::text) AS last_runned,
           to_char(max(co.end_timestamp) - max(co.begin_timestamp), 'YYYY-MM-DD"T"HH24:MI:SS'::text) AS elapsed_time,
           s.status
    FROM config_model.schedule s
         LEFT JOIN config_model.ctrl_orch co ON co.orch_id = s.orch_id
    GROUP BY s.id, s.orch_id, s.frequency_mask;