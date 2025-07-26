    CREATE OR REPLACE VIEW config_model.v_availability AS
    SELECT alert_rule,
           alert_context AS context,
           fired_date_time AS fired_date,
           resolved_date_time AS resolved_date,
           to_char(to_char(resolved_date_time, 'HH24:MI'::text)::time without time zone
                   - to_char(fired_date_time, 'HH24:MI'::text)::time without time zone,
                   'HH24:MI'::text) AS duration_downtime
    FROM config_model.availability_log al
    GROUP BY alert_rule, alert_context, fired_date_time, resolved_date_time
    ORDER BY fired_date_time;