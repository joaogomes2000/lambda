CREATE OR REPLACE VIEW config_model.fe_view_connection_management AS
    SELECT c.id AS connection_id,
           c.description AS name,
           a.description AS application,
           CASE
               WHEN pt.description::text = 'Transportation'::text THEN 'File'::character varying
               ELSE pt.description
           END AS connection_type,
           to_char(COALESCE(c.update_date, c.creation_date), 'YYYY-MM-DD"T"HH24:MI:SS'::text) AS last_updated,
           COALESCE(c.update_user, c.create_user) AS last_updated_by,
           count(os.id) AS used_count
    FROM config_model.connections c
         JOIN config_model.applications a ON c.app_id = a.id
         JOIN config_model.protocol_type pt ON c.protocol_type_id = pt.id
         LEFT JOIN config_model.orch_steps os ON os.connection_id = c.id
    GROUP BY c.id, c.description, a.description, pt.description, c.update_date, c.creation_date, c.update_user, c.create_user;