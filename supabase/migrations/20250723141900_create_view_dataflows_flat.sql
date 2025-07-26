create or replace view public.dataflows_flat as
select
  df.*,
  e.name         as entity_name,
  ac.name        as connector_name,
  ac.type::text  as connector_type,
  ac.direction   as connector_direction,
  app.name       as application_name
from data_flows df
left join entities e on df.entity_id = e.id
left join application_connectors ac on df.application_connector_id = ac.id
left join applications app on ac.application_id = app.id;