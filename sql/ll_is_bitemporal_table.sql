CREATE OR REPLACE FUNCTION bitemporal_internal.ll_is_bitemporal_table (p_table text)
    RETURNS boolean IMMUTABLE
    AS $$
DECLARE
    v_schemaname text;
    v_tablename text;
BEGIN
    SELECT
        split_part(p_table, '.', 1) INTO v_schemaname;
    SELECT
        split_part(p_table, '.', 2) INTO v_tablename;
    RETURN (
        SELECT
            coalesce(max(
                    CASE WHEN a.attname = 'asserted' THEN
                        1
                    ELSE
                        0
                    END), 0) + coalesce(max(
                    CASE WHEN a.attname = 'effective' THEN
                        1
                    ELSE
                        0
                    END), 0) = 2
            AND EXISTS (
                SELECT
                    1
                FROM
                    pg_attribute ac
                    JOIN pg_class cc ON ac.attrelid = cc.oid
                        AND ac.attname = 'row_created_at'
                    JOIN pg_namespace n ON n.oid = cc.relnamespace
                        AND n.nspname = v_schemaname
                        AND cc.relname = v_tablename)
                FROM
                    pg_class c
                JOIN pg_namespace n ON n.oid = c.relnamespace
                    AND relkind = 'i'
                JOIN pg_am am ON am.oid = c.relam
                JOIN pg_index x ON c.oid = x.indexrelid
                    AND amname = 'gist'
                    AND indisexclusion = 'true'
                JOIN pg_class cc ON cc.oid = x.indrelid
                JOIN pg_attribute a ON a.attrelid = c.oid
                JOIN pg_type t ON a.atttypid = t.oid
                --   join pg_attribute ac ON ac.attrelid=cc.oid
            WHERE
                n.nspname = v_schemaname
                AND cc.relname = v_tablename);
END;
$$
LANGUAGE plpgsql;

