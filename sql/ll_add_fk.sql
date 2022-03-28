CREATE OR REPLACE FUNCTION bitemporal_internal.ll_add_fk (p_schema_name text, p_table_name text, p_column_name text, p_source_schema_name text, p_source_table_name text, p_source_column_name text)
    RETURNS text
    AS $BODY$
DECLARE
    v_fk_constraint_name text;
    v_function_name text;
    v_trigger_function_name text;
    v_return_type text;
BEGIN
    IF bitemporal_internal.validate_bitemporal_pk_uq (p_source_schema_name, p_source_table_name, p_source_column_name) IS NULL THEN
        RETURN 'no primary key or unique constraint';
        exit;
    END IF;
    v_return_type: = temporal_relationships.get_column_type (p_source_schema_name, p_source_table_name, p_source_column_name);
    v_fk_constraint_name: = bitemporal_internal.fk_constraint (p_column_name, p_source_table_name, p_source_column_name);
    EXECUTE format($a$ ALTER TABLE % s. % s
            ADD % s $a$, p_schema_name, p_table_name, v_fk_constraint_name);
    IF NOT bitemporal_internal.ll_lookup_validation_function (p_source_schema_name, p_source_table_name, p_source_column_name) THEN
        SELECT
            * INTO v_function_name
        FROM
            bitemporal_internal.ll_generate_fk_validate (p_source_schema_name, p_source_table_name, p_source_column_name);
    END IF;

    /*do not need to check whether this constraint already exists,
     it will error, if exists */
    SELECT
        * INTO v_trigger_function_name
    FROM
        bitemporal_internal.ll_generate_fk_trigger_function (p_schema_name, p_table_name, p_column_name);
    EXECUTE format($create_tg$ CREATE TRIGGER t_RI_bt_insert_ % s_ % s
            BEFORE INSERT OR UPDATE ON % s. % s
            FOR EACH ROW
            EXECUTE PROCEDURE % s (% s, % s, % s ) $create_tg$, p_table_name, p_column_name, p_schema_name, p_table_name, v_trigger_function_name, p_schema_name, p_table_name, p_column_name );
    RETURN v_fk_constraint_name;
END;
$BODY$
LANGUAGE plpgsql;

