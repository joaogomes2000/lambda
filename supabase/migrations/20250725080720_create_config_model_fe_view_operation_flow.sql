CREATE OR REPLACE VIEW config_model.fe_view_operation_flow AS
    SELECT DISTINCT oh.id AS flow_id,
           oh.name AS flow_name,
           oh.description AS flow_description,
           CASE
               WHEN string_agg(DISTINCT ft.name::text, ', '::text) ~~ '%inbound%outbound%'::text THEN 'End-to-End'::text
               WHEN string_agg(DISTINCT ft.name::text, ', '::text) ~~ '%inbound%'::text THEN 'Inbound'::text
               WHEN string_agg(DISTINCT ft.name::text, ', '::text) ~~ '%outbound%'::text THEN 'Outbound'::text
               ELSE 'Internal'::text
           END AS direction,
           string_agg(DISTINCT a.description::text, ', '::text) AS application,
           string_agg(DISTINCT av.name::text, ', '::text) AS application_version,
           string_agg(DISTINCT dd.domain_name::text, ', '::text) AS entity,
           string_agg(DISTINCT pt.description::text, ', '::text) FILTER (
               WHERE pt.description::text <> ALL (ARRAY['Sync'::character varying::text, 'Transportation'::character varying::text])
           ) AS protocol,
           CASE
               WHEN string_agg(DISTINCT pt.description::text, ', '::text) ~~ '%Sync%'::text THEN true
               ELSE false
           END AS persist_rp,
           to_char(max(co.begin_timestamp), 'YYYY-MM-DD"T"HH24:MI:SS'::text) AS last_runned,
           to_char(max(co.end_timestamp) - max(co.begin_timestamp), 'HH24:MI:SS'::text) AS last_execution_time_elapsed,
           '0 * * * *'::text AS scheduler,
           CASE
               WHEN oh.status::text = 'A'::text THEN 'Active'::text
               WHEN oh.status::text = 'I'::text THEN 'Inactive'::text
               WHEN oh.status::text = 'W'::text THEN 'Inactive'::text
               ELSE NULL::text
           END AS status,
           to_char(oh.creation_date, 'YYYY-MM-DD"T"HH24:MI:SS'::text) AS creation_date,
           to_char(oh.update_date, 'YYYY-MM-DD"T"HH24:MI:SS'::text) AS update_date,
           oh.update_user
    FROM config_model.orch_head oh
         LEFT JOIN config_model.schedule s ON oh.id = s.orch_id
         LEFT JOIN config_model.ctrl_orch co ON co.orch_id = oh.id
         JOIN config_model.orch_steps os ON os.orch_id = oh.id
         JOIN config_model.data_domain_app_versions ddav ON ddav.id = os.data_domain_app_version_id
         JOIN config_model.data_domains dd ON ddav.data_domain_id = dd.id
         JOIN config_model.application_versions av ON ddav.app_version_id = av.id
         JOIN config_model.applications a ON av.app_id = a.id
         JOIN config_model.protocol_type pt ON ddav.protocol_type_id = pt.id
         JOIN config_model.flow_type ft ON ddav.flow_type_id = ft.id
    WHERE ft.name::text <> 'internal'::text
    GROUP BY oh.id, s.frequency_mask, s.status, s.creation_date, s.update_date, s.update_user;