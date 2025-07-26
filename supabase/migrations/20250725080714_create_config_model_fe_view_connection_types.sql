CREATE OR REPLACE VIEW config_model.fe_view_connection_types AS
    SELECT id,
           name,
           description,
           status,
           create_user,
           creation_date,
           update_user,
           update_date
    FROM config_model.protocol_type pt
    WHERE name::text = ANY (ARRAY['file'::character varying::text, 'db'::character varying::text, 'api'::character varying::text]);