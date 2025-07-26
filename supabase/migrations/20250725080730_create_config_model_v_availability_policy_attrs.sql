    CREATE OR REPLACE VIEW config_model.v_availability_policy_attrs AS
    SELECT ap.policy_id,
           ap.alert_rule,
           ap.severity,
           ap.context,
           a.name AS attr_name,
           pa.attr_value,
           pa.status
    FROM config_model.availability_policy ap
         JOIN config_model.policies_attrs pa ON ap.policy_id = pa.policy_id
         JOIN config_model.attributes a ON pa.attr_id = a.id
    WHERE ap.policy_id IS NOT NULL;