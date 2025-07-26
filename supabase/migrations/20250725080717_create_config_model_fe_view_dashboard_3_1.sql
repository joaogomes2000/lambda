    CREATE OR REPLACE VIEW config_model.fe_view_dashboard_3_1 AS
    SELECT ft.name AS flow_type,
           count(1) AS num_operations
    FROM config_model.orch_steps os
         JOIN config_model.data_domain_app_versions ddav
           ON ddav.id = os.data_domain_app_version_id
         JOIN config_model.flow_type ft
           ON ft.id = ddav.flow_type_id
    WHERE ft.name::text <> 'internal'::text
    GROUP BY ft.name;