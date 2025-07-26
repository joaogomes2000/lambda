CREATE OR REPLACE VIEW config_model.fe_view_applications AS
    SELECT id,
           name,
           description,
           product_definition,
           status,
           create_user,
           creation_date,
           update_user,
           update_date
    FROM config_model.applications a
    WHERE name::text <> 'katalist'::text;