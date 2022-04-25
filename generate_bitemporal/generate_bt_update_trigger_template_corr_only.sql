create or replace function generate_bt_update_trigger_template_corr_only (p_table_name text) 
returns text
as
$function_body$
DECLARE 
v_trigger_text text;
v_list_of_fields_ext text;
v_list_of_values_ext text:=' ';
v_list_of_fields_arr text[];
v_schema_name text;
v_table_name text;
v_bt_table_name text;
v_current_field text;
BEGIN
select split_part(p_table_name,'.',1) into v_schema_name;
select split_part(p_table_name,'.',2) into v_table_name;
v_bt_table_name:=v_schema_name||'_bitemporal.'||v_table_name;
select bitemporal_internal.ll_bitemporal_list_of_fields(v_bt_table_name) into v_list_of_fields_arr;
v_list_of_fields_ext:=array_to_string(v_list_of_fields_arr, ',');
FOREACH v_current_field in array v_list_of_fields_arr LOOP
/*if v_list_of_values_ext>' ' then
v_list_of_values_ext:=v_list_of_values_ext||',';
end if;
*/
v_list_of_values_ext:=v_list_of_values_ext||$nxt$||$$,$$||case when NEW.$nxt$||v_current_field|| $nxt$ is NULL then 'NULL' else $$'$$||NEW.$nxt$||v_current_field|| $nxt$ ||$$'$$ end 
 $nxt$;    
END LOOP;
v_trigger_text:=format($tt$
CREATE OR REPLACE FUNCTION %s_update_bitemp()
  RETURNS trigger AS
$BODY$
 DECLARE   v_list_of_fields text :=%L;
           v_list_of_values text;
           v_effective tstzrange; 
           
BEGIN  
--SELECT tstzrange(now(), 'infinity', '[)') into v_effective; 
SELECT distinct(effective) into v_effective 
   from %s where %s_id=new.%s_id;  /* review */
 v_list_of_values :=%s;  /*remove id*/
 perform bitemporal_internal.ll_bitemporal_correction(%L ,
v_list_of_fields,v_list_of_values,
'table_id', /* review */
NEW.table_id::text,/* review */
v_effective
);
 return new;
END;
    
$BODY$
  LANGUAGE plpgsql VOLATILE;
$tt$,
p_table_name,
v_list_of_fields_ext,
v_bt_table_name,
v_table_name,
v_table_name,
v_list_of_values_ext,
v_bt_table_name
 ); 

return v_trigger_text;
end;
$function_body$
language plpgsql;
