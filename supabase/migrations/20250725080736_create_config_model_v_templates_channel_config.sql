    CREATE OR REPLACE VIEW config_model.v_templates_channel_config AS
    SELECT tc.alert_rule,
           tc.severity,
           tc.context,
           tc.error_code_id,
           tc.template_title,
           tc.template_body,
           tc.template_required_fields,
           tc.status AS templates_status,
           cc.id AS channel_id,
           cc.name AS channel_name,
           cc.status AS channel_status
    FROM config_model.templates_config tc
         JOIN config_model.channel_config cc ON tc.channel_id = cc.id;