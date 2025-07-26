CREATE VIEW application_connectors_view AS
SELECT *, type::text AS type_text
FROM application_connectors;