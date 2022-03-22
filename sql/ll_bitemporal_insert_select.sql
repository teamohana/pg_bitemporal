CREATE OR REPLACE FUNCTION bitemporal_internal.ll_bitemporal_insert_select (p_table text, p_list_of_fields text, p_select text, p_effective temporal_relationships.timeperiod, p_asserted temporal_relationships.timeperiod)
    RETURNS integer
    AS $BODY$
DECLARE
    v_rowcount integer;
BEGIN
    EXECUTE format($i$ INSERT INTO % s (% s, effective, asserted)
        SELECT
            a.*, % L, % L FROM (% s) a
        RETURNING
            * $i$, p_table, p_list_of_fields, p_effective, p_asserted, p_select);
    GET DIAGNOSTICS v_rowcount: = ROW_COUNT;
    RETURN v_rowcount;
END;
$BODY$
LANGUAGE plpgsql;

