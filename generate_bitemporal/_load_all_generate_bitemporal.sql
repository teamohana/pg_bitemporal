begin;
set search_path to bitemporal_internal, public;

\ir ll_generate_bitem_for_schema.sql
--the triggers generation is not 100% automated, thr funcitons below produce the draft of the code
--which should be finalized manually
\ir generate_bt_insert_trigger_template.sql
\ir generate bt_update_trigger_template.sql
\ir generate bt_update_trigger_template_corr_only.sql

commit;
