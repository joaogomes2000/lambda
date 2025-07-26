    CREATE OR REPLACE VIEW config_model.v_connection_attrs AS
    SELECT ca.connection_id,
           c.description,
           c.app_id,
           c.protocol_type_id,
           c.status AS connection_status,
           ca.attr_id,
           ca.attr_value,
           ca.required,
           ca.status AS attr_status,
           a.name AS attr_name,
           a.attr_lov_id
    FROM config_model.connection_attrs ca
         JOIN config_model.attributes a ON ca.attr_id = a.id
         JOIN config_model.connections c ON ca.connection_id = c.id;