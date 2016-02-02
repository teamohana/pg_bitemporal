BEGIN;
SELECT plan( 13 );

set local search_path = bitemporal_internal, 'temporal_relationships','public';


select lives_ok($$
create table t9 ( 
id serial primary key
, name text                                                                                                        
, mark int
, node_id int
, unique (name)
, unique ( mark )
, constraint "bitemporal fk 1" check ( true or 'fk' <> '@node_id -> sg.networks(network_id)@') 
, constraint "bitemporal fk 2" check ( true or 'fk' <>'@node_id -> networks(id)@' ) 
, constraint "bitemporal unique 3" check ( true or 'u' <> 'name' )
, constraint "bitemporal pk 1" check ( true or 'pk' <> '@id@')
) 
$$);

--   consrc                                          
-- ---------------------+---------+----------+-----------------------------------------------------------------------------------------
--  bitemporal fk 1     | c       |  1625561 | (true OR ('fk'::text <> '@node_id -> sg.networks network_id@'::text))
--  bitemporal fk 2     | c       |  1625561 | (true OR ('fk'::text = ANY (ARRAY['node_id'::text, 'cnu.networks'::text, 'id'::text])))
--  bitemporal unique 3 | c       |  1625561 | (true OR ('col'::text = 'name'::text))
-- 

select lives_ok($$
   select bitemporal_conname_prefix() ;
$$, 'bitemporal_conname_prefix' );

select is(mk_conname('a','b','c','d') 
, format('%s a bcd', bitemporal_conname_prefix() ) 
, 'mk_conname');


select is( mk_constraint('type', 'name', 'source') 
, $$CONSTRAINT name check(true or 'type' <> '@source@') $$
, 'mk_constraint');

select is( pk_constraint('src_column')
, $$CONSTRAINT "bitemporal pk src_column" check(true or 'pk' <> '@src_column@') $$
, 'pk_constraint');


--  format('% -> %(%)', src_column, fk_table, fk_column)
select is( fk_constraint('a', 'b', 'c') 
, $$CONSTRAINT "bitemporal fk abc" check(true or 'fk' <> '@a -> b(c)@') $$
, 'fk_constraint');

select alike( unique_constraint('a') 
, 'CONSTRAINT % EXCLUDE USING gist%(a WITH =, asserted WITH &&, effective WITH &&)'
, 'unique_constraint' );

--   CONSTRAINT devices_device_id_asserted_effective_excl EXCLUDE 
--  USING gist (device_id WITH =, asserted WITH &&, effective WITH &&)


select is( select_constraint_value($$asdfasdfasdf '@XXX@' $$)
, 'XXX'
, 'select_constraint_value' );

select is(add_constraint('t9', 'XXX')
, $$alter table t9 add XXX$$
, 'add_constraint');

select is( find_bitemporal_pk('t9') , $$id$$ , 'find_bitemporal_pk');


select bag_eq( $$ 
  select * from find_bitemporal_fk('t9') 
$$,
$$ 
  values 
 ('bitemporal fk 1', 'node_id','sg.networks','network_id') 
, ('bitemporal fk 2','node_id','networks','id' )
$$ 
, 'find_bitemporal_fk');

select results_eq($$
select count(*)::int from find_bitemporal_constraints('t9', '%' ) 
$$
, $$ 
values ( 4::int ) 
$$, 'find_bitemporal_constraints');

select has_relation('bitemporal_fk_constraint_type', 'table bitemporal_fk_constraint_type exists');

SELECT * FROM finish();
ROLLBACK;

-- vim: set filetype=pgsql expandtab tabstop=2 shiftwidth=2:
