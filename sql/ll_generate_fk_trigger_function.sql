CREATE OR REPLACE FUNCTION bitemporal_internal.ll_generate_fk_trigger_function (p_schema_name text, p_table_name text, p_column_name text)
    RETURNS text
    AS $BODY_AUTO$
DECLARE
    t text;
    v_trigger_function_name text;
    v_trigger_name text;
    v_return_type text;
BEGIN
    v_trigger_function_name: = p_schema_name || '.RI_BT_FKey_check_ins_' || p_column_name;
    t: = format($execute$ CREATE OR REPLACE FUNCTION % s ( )
            RETURNS TRIGGER AS $TR_BODY$ /*  TG_ARGV[0] is a schema name
  TG_ARGV[1] is a table name
  TG_ARGV[2] is a column name
  */
DECLARE
    v_value anyelement;
    v_result boolean;
BEGIN
    v_value: = NEW. % s;
    EXECUTE format($ef$
        SELECT
            * FROM % % s.validate_bitemporal_ % % s_ % % s (% % s, $1, $2) $ef$, TG_ARGV[0], TG_ARGV[1], TG_ARGV[2], v_value) INTO v_result
    USING NEW.effective, NEW.asserted;
    IF v_result IS FALSE THEN
        RAISE EXCEPTION '%%  %% foreign key constraint violated', TG_ARGV[2], NEW. % s;
    END IF;
    RETURN new;
    END;
    $TR_BODY$
    LANGUAGE plpgsql;
    $execute$,
    v_trigger_function_name,
    p_column_name,
    p_column_name);
    --raise notice 'code:%',t;
    RETURN v_trigger_function_name;
END;
$BODY_AUTO$
LANGUAGE plpgsql
VOLATILE;

