CREATE OR REPLACE FUNCTION bitemporal_internal.ll_lookup_validation_function (p_schema_name text, p_table_name text, p_column_name text)
    RETURNS boolean IMMUTABLE
    AS $$
    SELECT
        count(*) = 1
    FROM
        pg_proc p
        JOIN pg_namespace n ON n.oid = p.pronamespace
            AND proname = 'validate_bt_' || p_table_name || '_' || p_column_name
            AND n.nspname = p_schema_name;

$$
LANGUAGE sql;

