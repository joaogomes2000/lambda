    CREATE OR REPLACE VIEW config_model.v_orch_step_attrs AS
    SELECT os.orch_id,
           pt.name AS protocol_name,
           a.name AS attr_name,
           osa.attr_id,
           osa.attr_value,
           osa.required,
           a.attr_lov_id,
           osa.status AS attr_status
    FROM config_model.orch_steps os
         JOIN config_model.orch_step_attrs osa ON osa.orch_step_id = os.id
         JOIN config_model.attributes a ON osa.attr_id = a.id
         JOIN config_model.protocol_type pt ON a.protocol_type_id = pt.id;