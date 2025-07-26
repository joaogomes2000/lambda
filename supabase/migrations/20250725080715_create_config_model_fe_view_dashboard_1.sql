CREATE OR REPLACE VIEW config_model.fe_view_dashboard_1 AS
    SELECT datetime,
           status,
           sum(num_operations) AS num_operations
    FROM (
        SELECT to_char(co.creation_date, 'YYYY-MM-DD"T"HH24'::text) AS datetime,
               CASE
                   WHEN co.status::text = 'P'::text THEN 'Processed'::text
                   WHEN co.status::text = 'W'::text THEN 'Processing'::text
                   WHEN co.status::text = 'R'::text THEN 'Recovered'::text
                   WHEN co.status::text = 'Q'::text THEN 'Processing'::text
                   WHEN co.status::text = 'E'::text THEN 'Error'::text
                   ELSE NULL::text
               END AS status,
               count(1) AS num_operations
        FROM config_model.ctrl_orch co
        WHERE to_char(co.creation_date, 'YYYY-MM-DD'::text)
              > to_char(CURRENT_DATE - '15 days'::interval, 'YYYY-MM-DD'::text)
              AND (
                  SELECT count(1) AS count
                  FROM (
                      SELECT os.orch_id, ft.name AS flow_type
                      FROM config_model.orch_steps os
                      JOIN config_model.data_domain_app_versions ddav
                        ON ddav.id = os.data_domain_app_version_id
                      JOIN config_model.flow_type ft
                        ON ft.id = ddav.flow_type_id
                      WHERE os.orch_id = co.orch_id
                      GROUP BY os.orch_id, ft.name
                  ) unnamed_subquery_1
                  WHERE unnamed_subquery_1.flow_type::text <> 'internal'::text
              ) > 0
        GROUP BY to_char(co.creation_date, 'YYYY-MM-DD"T"HH24'::text), co.status
    ) unnamed_subquery
    GROUP BY datetime, status;