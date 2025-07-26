    CREATE OR REPLACE VIEW config_model.v_orch_step_attributes AS
    SELECT os.orch_id,
           os.id AS orch_step_number,
           dd.domain_name,
           (SELECT 1 FROM config_model.orch_step_app_instances ost
            WHERE ost.orch_step_id = os.id
            LIMIT 1) AS has_targets,
           pt.name AS transport_protocol,
           ft.name AS flow_type_name,
           a.name AS attribute_name,
           ddava.attr_value AS ddava_attr_value,
           ca.attr_value AS ca_attr_value,
           osa.attr_value AS osa_attr_value,
           a.required AS attr_required
    FROM config_model.orch_steps os
         JOIN config_model.data_domain_app_versions ddav ON ddav.id = os.data_domain_app_version_id
         JOIN config_model.data_domains dd ON dd.id = ddav.data_domain_id
         JOIN config_model.protocol_type pt ON ddav.protocol_type_id = pt.id
         JOIN config_model.flow_type ft ON ddav.flow_type_id = ft.id
         JOIN config_model.attributes a ON
             (a.protocol_type_id = ddav.protocol_type_id OR a.protocol_type_id IS NULL)
             AND (a.flow_type_id = ddav.flow_type_id OR a.flow_type_id IS NULL)
             AND (a.context::text <> 'Connection'::text OR
                  a.context::text = 'Connection'::text AND os.connection_id IS NOT NULL)
         LEFT JOIN config_model.connections c ON c.id = os.connection_id AND c.status::text = 'A'::text
         LEFT JOIN config_model.data_domain_app_version_attrs ddava ON ddava.data_domain_app_version_id = ddav.id
              AND ddava.attr_id = a.id AND ddava.status::text = 'A'::text
         LEFT JOIN config_model.connection_attrs ca ON ca.connection_id = c.id
              AND ca.attr_id = a.id AND ca.status::text = 'A'::text
         LEFT JOIN config_model.orch_step_attrs osa ON osa.orch_step_id = os.id
              AND osa.attr_id = a.id AND osa.status::text = 'A'::text
    WHERE os.status::text = 'A'::text
          AND (ddava.attr_value IS NOT NULL
               OR ca.attr_value IS NOT NULL
               OR osa.attr_value IS NOT NULL
               OR (ddava.attr_value IS NULL
                   AND ca.attr_value IS NULL
                   AND osa.attr_value IS NULL
                   AND a.required = true))
    GROUP BY os.id, os.orch_step, pt.name, ft.name, a.name,
             ddava.attr_value, ca.attr_value, osa.attr_value, dd.domain_name, a.required;