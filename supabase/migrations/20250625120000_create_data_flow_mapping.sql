create type mappingstatus as enum ('A', 'I');
create type mappingtype as enum ('python', 'json', 'sql');

create table data_flow_mapping (
    id serial primary key,
    data_flow_id integer not null references data_flows(id),
    status mappingstatus not null,
    entity_schema json,
    sample text,
    client_schema json,
    transformations_rules text,
    script text,
    mapping_type mappingtype not null,
    mark_as_deleted BOOLEAN DEFAULT false
);