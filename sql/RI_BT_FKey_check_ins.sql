CREATE OR REPLACE FUNCTION bitemporal_internal.ri_bt_fkey_check_ins ()
    RETURNS TRIGGER
    LANGUAGE 'plpgsql'
    COST 100.0
    AS $BODY$
    /*  TG_ARGV[0] is a schema name
     TG_ARGV[1] is a table name
     TG_ARGV[2] is a column name
     */
DECLARE
    v_value integer;
    v_result boolean;
BEGIN
    v_value: = NEW.device_id;
    EXECUTE format($ef$
        SELECT
            * FROM % s.validate_bitemporal_ % s_ % s (% s, $1, $2) $ef$, TG_ARGV[0], TG_ARGV[1], TG_ARGV[2], v_value) INTO v_result
    USING NEW.effective, NEW.asserted;
    IF v_result IS FALSE THEN
        RAISE EXCEPTION '% % foreign key constraint violated', TG_ARGV[2], NEW.device_id;
    END IF;
    RETURN new;
END;
$BODY$;

