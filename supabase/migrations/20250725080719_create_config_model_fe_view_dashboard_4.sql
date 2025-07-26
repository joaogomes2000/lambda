CREATE OR REPLACE VIEW config_model.fe_view_dashboard_4 AS
    SELECT status,
           num_operations * 100::numeric / total_operations AS status_percent
    FROM (
        SELECT fe_view_dashboard_1.status,
               sum(fe_view_dashboard_1.num_operations) AS num_operations,
               (
                   SELECT sum(fe_view_dashboard_1_1.num_operations) AS sum
                   FROM config_model.fe_view_dashboard_1 fe_view_dashboard_1_1
               ) AS total_operations
        FROM config_model.fe_view_dashboard_1
        GROUP BY fe_view_dashboard_1.status
    ) unnamed_subquery;