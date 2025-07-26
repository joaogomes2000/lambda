    CREATE OR REPLACE VIEW config_model.fe_view_dashboard_2 AS
    SELECT to_char(efc.insertion_timestamp, 'YYYY-MM-DD"T"HH24'::text) AS date,
           'file'::text AS type,
           sum(COALESCE(efc.file_num_lines, 0)) AS records
    FROM config_model.exec_file_control efc
    WHERE to_char(efc.insertion_timestamp, 'YYYY-MM-DD'::text)
          > to_char(CURRENT_DATE - '15 days'::interval, 'YYYY-MM-DD'::text)
    GROUP BY to_char(efc.insertion_timestamp, 'YYYY-MM-DD"T"HH24'::text)

    UNION

    SELECT to_char(eac.insertion_timestamp, 'YYYY-MM-DD"T"HH24'::text) AS date,
           'api'::text AS type,
           sum(COALESCE(eac.lines_processed, 0)) AS records
    FROM config_model.exec_api_control eac
    WHERE to_char(eac.insertion_timestamp, 'YYYY-MM-DD'::text)
          > to_char(CURRENT_DATE - '15 days'::interval, 'YYYY-MM-DD'::text)
    GROUP BY to_char(eac.insertion_timestamp, 'YYYY-MM-DD"T"HH24'::text)

    UNION

    SELECT to_char(edc.insertion_timestamp, 'YYYY-MM-DD"T"HH24'::text) AS date,
           'db'::text AS type,
           sum(COALESCE(edc.lines_processed, 0)) AS records
    FROM config_model.exec_db_control edc
    WHERE to_char(edc.insertion_timestamp, 'YYYY-MM-DD'::text)
          > to_char(CURRENT_DATE - '15 days'::interval, 'YYYY-MM-DD'::text)
    GROUP BY to_char(edc.insertion_timestamp, 'YYYY-MM-DD"T"HH24'::text);