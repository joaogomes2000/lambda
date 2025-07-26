CREATE OR REPLACE VIEW config_model.v_availability_report AS
    SELECT component_name,
           resource_type,
           to_char(fired_date_time, 'YYYY-MM-DD HH24:MI:SS'::text) AS downtime,
           to_char(resolved_date_time, 'YYYY-MM-DD HH24:MI:SS'::text) AS uptime,
           to_char(sum(resolved_date_time - fired_date_time), 'HH24:MI:SS'::text) AS time_elapsed
    FROM config_model.availability_log al
    WHERE resolved_date_time IS NOT NULL
    GROUP BY component_name, resource_type, fired_date_time, resolved_date_time,
             to_char(creation_date, 'YYYY-MM-DD'::text)
    ORDER BY to_char(creation_date, 'YYYY-MM-DD'::text) DESC;