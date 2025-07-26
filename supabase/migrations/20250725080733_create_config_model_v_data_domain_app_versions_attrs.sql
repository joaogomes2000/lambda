    CREATE OR REPLACE VIEW config_model.v_data_domain_app_versions_attrs AS
    SELECT ddava.data_domain_app_version_id,
           ddav.app_version_id,
           ddav.data_domain_id,
           ddav.protocol_type_id,
           ddav.flow_type_id,
           ddava.attr_id,
           ddava.attr_value,
           ddava.required,
           a.name AS attr_name,
           a.attr_lov_id
    FROM config_model.data_domain_app_version_attrs ddava
         JOIN config_model.attributes a ON ddava.attr_id = a.id
         JOIN config_model.data_domain_app_versions ddav ON ddava.data_domain_app_version_id = ddav.id;