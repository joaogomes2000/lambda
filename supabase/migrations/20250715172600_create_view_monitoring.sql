CREATE VIEW latest_status_by_dataflow_files AS
SELECT 
  MAX(t2.position) AS max_position,
  t2.id AS status_id,
  t0.dataflow_id AS dataflow_id
FROM  monitoring_dataflow_files t0 
LEFT JOIN status t2 ON t0.statusid = t2.id
GROUP BY t0.id, t2.id;

-------------------------------//------------------------------------------
CREATE VIEW latest_status_by_dataflow_db AS
SELECT 
  MAX(t2.position) AS max_position,
  t2.id AS status_id,
  t0.dataflow_id AS dataflow_id
FROM  monitoring_dataflow_db t0 
LEFT JOIN status t2 ON t0.statusid = t2.id
GROUP BY t0.id, t2.id;

-------------------------------//------------------------------------------

CREATE VIEW latest_status_by_dataflow_api AS
SELECT 
  MAX(t2.position) AS max_position,
  t2.id AS status_id,
  t0.dataflow_id AS dataflow_id
FROM  monitoring_dataflow_api t0 
LEFT JOIN status t2 ON t0.statusid = t2.id
GROUP BY t0.id, t2.id;

-------------------------------//------------------------------------------

CREATE VIEW latest_status_by_orchestrations AS
SELECT 
  MAX(t2.position) AS max_position,
  t2.id AS status_id,
  t0.execution_orchestration_id AS execution_orchestration_id
FROM  monitoring_dataflow t0 
LEFT JOIN status t2 ON t0.statusid = t2.id
GROUP BY t0.id, t2.id;


