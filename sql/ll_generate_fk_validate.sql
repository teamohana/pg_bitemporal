CREATE OR REPLACE FUNCTION bitemporal_internal.ll_generate_fk_validate (p_schema_name text, p_table_name text, p_column_name text)
    RETURNS text
    AS $BODY_AUTO$
DECLARE
    t text;
    v_function_name text;
    --v_return_type text;
BEGIN
    v_function_name: = 'validate_bt_' || p_table_name || '_' || p_column_name;

    /*v_return_type :=temporal_relationships.get_column_type(
     p_schema_name ,
     p_table_name ,                                            
     p_column_name );*/
    --EXECUTE
    t: = format($execute$ CREATE OR REPLACE FUNCTION % s. % s (p_value anyelement, p_effective temporal_relationships.timeperiod, p_asserted temporal_relationships.timeperiod )
            RETURNS boolean AS $BODY$
DECLARE
    v_record record;
    i integer: = 0;
    v_min_low_effective temporal_relationships.time_endpoint;
    v_max_upper_effective temporal_relationships.time_endpoint;
    v_min_low_asserted temporal_relationships.time_endpoint;
    v_max_upper_asserted temporal_relationships.time_endpoint;
BEGIN
    FOR v_record IN
    SELECT
        effective
    FROM
        % s. % s
    WHERE
        % s = p_value
        AND temporal_relationships.has_includes (effective, p_effective)
        AND temporal_relationships.has_includes (asserted, p_asserted)
    ORDER BY
        lower(effective),
        upper(effective)
        LOOP
            IF i = 0 THEN
                IF lower(p_effective) < lower(v_record.effective) THEN
                    RETURN FALSE;
                ELSE
                    v_min_low_effective: = lower(v_record.effective);
                    v_max_upper_effective: = upper(v_record.effective);
                END IF;
            END IF;
            i: = i + 1;
            IF lower(v_record.effective) > v_max_upper_effective THEN
                RAISE NOTICE 'false- gap in effective!';
                RETURN FALSE;
            ELSE
                IF upper(v_record.effective) > v_max_upper_effective ---sanity check
                    THEN
                    v_max_upper_effective: = upper(v_record.effective);
                END IF;
            END IF;
        END LOOP;
    IF i = 0 THEN
        RETURN FALSE;
    END IF;
    IF v_max_upper_effective < upper(p_effective) THEN
        RETURN FALSE;
    END IF;
    i: = 0;
    FOR v_record IN
    SELECT
        asserted
    FROM
        % s. % s
    WHERE
        % s = p_value
        AND temporal_relationships.has_includes (effective, p_effective)
        AND temporal_relationships.has_includes (asserted, p_asserted)
    ORDER BY
        lower(asserted),
        upper(asserted)
        LOOP
            IF i = 0 THEN
                IF lower(p_asserted) < lower(v_record.asserted) THEN
                    RETURN FALSE;
                ELSE
                    v_min_low_asserted: = lower(v_record.asserted);
                    v_max_upper_asserted: = upper(v_record.asserted);
                END IF;
            END IF;
            i: = i + 1;
            IF lower(v_record.asserted) > v_max_upper_asserted THEN
                RETURN FALSE;
            ELSE
                IF upper(v_record.asserted) > v_max_upper_asserted ---sanity check
                    THEN
                    v_max_upper_asserted: = upper(v_record.asserted);
                END IF;
            END IF;
        END LOOP;
    IF i = 0 THEN
        RETURN FALSE;
    END IF;
    IF v_max_upper_asserted < upper(p_asserted) THEN
        RETURN FALSE;
    END IF;
    RETURN TRUE;
    END;
    $BODY$
    LANGUAGE plpgsql
    $execute$,
    p_schema_name,
    v_function_name,
    v_return_type,
    p_schema_name,
    p_table_name,
    p_column_name,
    p_schema_name,
    p_table_name,
    p_column_name);
    RAISE NOTICE 'code:%', t;
    RETURN v_function_name;
END;
$BODY_AUTO$
LANGUAGE plpgsql
VOLATILE;

