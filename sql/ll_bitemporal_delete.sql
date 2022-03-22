CREATE OR REPLACE FUNCTION bitemporal_internal.ll_bitemporal_delete (p_table text, p_search_fields text, -- search fields
p_search_values text, --  search values
p_asserted temporal_relationships.timeperiod -- will be asserted
)
    RETURNS integer
    AS $BODY$
DECLARE
    v_rowcount INTEGER: = 0;
BEGIN
    --end assertion period for the current records record(s)
    EXECUTE format($u$ UPDATE
            % s
        SET
            asserted = temporal_relationships.timeperiod (lower(asserted), lower(% L::temporal_relationships.timeperiod))
            WHERE (% s) = (% s)
            AND lower(% L::temporal_relationships.timeperiod) <@ asserted $u$, p_table, p_asserted, p_search_fields, p_search_values, p_asserted);
    GET DIAGNOSTICS v_rowcount: = ROW_COUNT;
    RETURN v_rowcount;
END;
$BODY$
LANGUAGE plpgsql;

