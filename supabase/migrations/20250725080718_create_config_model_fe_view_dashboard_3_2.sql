    CREATE OR REPLACE VIEW config_model.fe_view_dashboard_3_2 AS
    SELECT flow_type,
           sum(records) AS total_records
    FROM (
        SELECT efc.flow_type,
               sum(COALESCE(efc.file_num_lines, 0)) AS records
        FROM config_model.exec_file_control efc
        WHERE to_char(efc.insertion_timestamp, 'YYYY-MM-DD'::text)
              > to_char(CURRENT_DATE - '30 days'::interval, 'YYYY-MM-DD'::text)
        GROUP BY to_char(efc.insertion_timestamp, 'YYYY-MM-DD'::text), efc.flow_type

        UNION

        SELECT eac.flow_type,
               sum(COALESCE(eac.lines_processed, 0)) AS records
        FROM config_model.exec_api_control eac
        WHERE to_char(eac.insertion_timestamp, 'YYYY-MM-DD'::text)
              > to_char(CURRENT_DATE - '30 days'::interval, 'YYYY-MM-DD'::text)
        GROUP BY to_char(eac.insertion_timestamp, 'YYYY-MM-DD'::text), eac.flow_type

        UNION

        SELECT edc.flow_type,
               sum(COALESCE(edc.lines_processed, 0)) AS records
        FROM config_model.exec_db_control edc
        WHERE to_char(edc.insertion_timestamp, 'YYYY-MM-DD'::text)
              > to_char(CURRENT_DATE - '30 days'::interval, 'YYYY-MM-DD'::text)
        GROUP BY to_char(edc.insertion_timestamp, 'YYYY-MM-DD'::text), edc.flow_type
    ) unnamed_subquery
    GROUP BY flow_type;