BEGIN;
CREATE SCHEMA IF NOT EXISTS temporal_relationships;
GRANT usage ON SCHEMA temporal_relationships TO public;
SET local search_path TO temporal_relationships, public;
-- create a domain if not exists
DO $d$
DECLARE
    domain_range_name text DEFAULT 'timeperiod';
    domain_range_type text DEFAULT 'tstzrange';
    domain_i_name text DEFAULT 'time_endpoint';
    domain_i_type text DEFAULT 'timestamptz';
BEGIN
    -- Create timeperiod domain
    PERFORM
        n.nspname AS "Schema",
        t.typname AS "Name",
        pg_catalog.format_type(t.typbasetype, t.typtypmod) AS "Type"
    FROM
        pg_catalog.pg_type t
    LEFT JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
WHERE
    t.typtype = 'd'
        AND n.nspname <> 'pg_catalog'
        AND n.nspname <> 'information_schema'
        AND pg_catalog.pg_type_is_visible(t.oid)
        AND t.typname = domain_range_name;
    IF FOUND THEN
        RAISE NOTICE 'Domain % already exists', domain_range_name;
    ELSE
        EXECUTE format('create domain %I as %I', domain_range_name, domain_range_type);
    END IF;
    -- Create time_endpoint domain
    PERFORM
        n.nspname AS "Schema",
        t.typname AS "Name",
        pg_catalog.format_type(t.typbasetype, t.typtypmod) AS "Type"
    FROM
        pg_catalog.pg_type t
    LEFT JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
WHERE
    t.typtype = 'd'
        AND n.nspname <> 'pg_catalog'
        AND n.nspname <> 'information_schema'
        AND pg_catalog.pg_type_is_visible(t.oid)
        AND t.typname = domain_i_name;
    IF FOUND THEN
        RAISE NOTICE 'Domain % already exists', domain_i_name;
    ELSE
        EXECUTE format('create domain %I as %I', domain_i_name, domain_i_type);
    END IF;
END;
$d$;
CREATE OR REPLACE FUNCTION timeperiod (p_range_start time_endpoint, p_range_end time_endpoint)
    RETURNS timeperiod
    LANGUAGE sql
    IMMUTABLE
    AS $func$
    SELECT
        tstzrange(p_range_start, p_range_end, '[)')::timeperiod;
$func$ SET search_path = 'temporal_relationships';
-- backwards compatible
CREATE OR REPLACE FUNCTION timeperiod_range (_s time_endpoint, _e time_endpoint, _ignored text)
    RETURNS timeperiod
    LANGUAGE sql
    AS $func$
    SELECT
        timeperiod (_s, _e);
$func$ SET search_path = 'temporal_relationships';
CREATE OR REPLACE FUNCTION XOR (a boolean, b boolean)
    RETURNS boolean
    LANGUAGE sql
    IMMUTABLE
    AS $$
    SELECT
        ((NOT a) <> (NOT b));
$$;
CREATE OR REPLACE FUNCTION fst (x anyrange)
    RETURNS anyelement
    LANGUAGE SQL
    IMMUTABLE
    AS $$
    SELECT
        lower(x);
$$;
CREATE OR REPLACE FUNCTION snd (x anyrange)
    RETURNS anyelement
    LANGUAGE SQL
    IMMUTABLE
    AS $$
    SELECT
        upper(x);
$$;
--
-- [starts] [starts^-1]
--
-- [starts A E]
--  A  |---|
--  E  |-------|
--
-- [starts^-1 A E]
--  A  |-------|
--  E  |---|
--
CREATE OR REPLACE FUNCTION has_starts (a timeperiod, b timeperiod)
    RETURNS boolean
    LANGUAGE SQL
    IMMUTABLE
    AS $$
    SELECT
        fst (a) = fst (b)
        AND snd (a) <> snd (b);
$$ SET search_path = 'temporal_relationships';
--
-- [finishes] [finishes^-1]
--
-- [finishes A E]
--  A  |-------|
--  E      |---|
--
-- [finishes^-1 A E]
--  A      |---|
--  E  |-------|
--
CREATE OR REPLACE FUNCTION has_finishes (a timeperiod, b timeperiod)
    RETURNS boolean
    LANGUAGE SQL
    IMMUTABLE
    AS $$
    SELECT
        snd (a) = snd (b)
        AND fst (a) <> fst (b);
$$ SET search_path = 'temporal_relationships';
--
-- [equals]
--
-- [equals A E]
--  A  |----|
--  E  |----|
--
CREATE OR REPLACE FUNCTION equals (a timeperiod, b timeperiod)
    RETURNS boolean
    LANGUAGE SQL
    IMMUTABLE
    AS $$
    -- doubtful = operator exists for timeperiod
    SELECT
        fst (a) = fst (b)
        AND snd (a) = snd (b);
$$ SET search_path = 'temporal_relationships';
--
-- [during]
--
-- [during A E]
--  A    |---|
--  E  |-------|
--
CREATE OR REPLACE FUNCTION is_during (a timeperiod, b timeperiod)
    RETURNS boolean
    LANGUAGE SQL
    IMMUTABLE
    AS $$
    SELECT
        (fst (a) > fst (b))
        AND (snd (a) < snd (b));
$$ SET search_path = 'temporal_relationships';
--
-- [during^-1] contained
--
-- [during^-1 A E]
--  A  |-------|
--  E    |---|
--
CREATE OR REPLACE FUNCTION is_contained_in (a timeperiod, b timeperiod)
    RETURNS boolean
    LANGUAGE SQL
    IMMUTABLE
    AS $$
    SELECT
        is_during (b, a);
$$ SET search_path = 'temporal_relationships';
--
-- [during] or [during^-1]
--
CREATE OR REPLACE FUNCTION has_during (a timeperiod, b timeperiod)
    RETURNS boolean
    LANGUAGE SQL
    IMMUTABLE
    AS $$
    SELECT
        is_during (a, b)
        OR is_during (b, a);
$$ SET search_path = 'temporal_relationships';
--
-- [overlaps]
--
-- [overlaps A E]
--  A  |-----|
--  E     |-----|
--
-- [overlaps^-1 A E]
--  A     |-----|
--  E  |-----|
--
CREATE OR REPLACE FUNCTION is_overlaps (a timeperiod, b timeperiod)
    RETURNS boolean
    LANGUAGE SQL
    IMMUTABLE
    AS $$
    SELECT
        fst (a) < fst (b)
        AND snd (a) > fst (b)
        AND snd (a) < snd (b);
$$ SET search_path = 'temporal_relationships';
--
-- either overlaps the other [overlaps] [overlaps^-1]
--
CREATE OR REPLACE FUNCTION has_overlaps (a timeperiod, b timeperiod)
    RETURNS boolean
    LANGUAGE SQL
    IMMUTABLE
    AS $$
    SELECT
        is_overlaps (a, b)
        OR is_overlaps (b, a);
$$ SET search_path = 'temporal_relationships';
--
-- [before]
--
-- [before A E]
--  A  |-----|
--  E           |-----|
--
CREATE OR REPLACE FUNCTION is_before (a timeperiod, b timeperiod)
    RETURNS boolean
    LANGUAGE SQL
    IMMUTABLE
    AS $$
    SELECT
        snd (a) < fst (b);
$$ SET search_path = 'temporal_relationships';
--
-- [before^-1]
--
-- [before^-1 A E]
--  A           |-----|
--  E   |-----|
--
CREATE OR REPLACE FUNCTION is_after (a timeperiod, b timeperiod)
    RETURNS boolean
    LANGUAGE SQL
    IMMUTABLE
    AS $$
    -- is_before(b, a)
    SELECT
        snd (b) < fst (a);
$$ SET search_path = 'temporal_relationships';
--
-- either [before] [before^-1]
--
CREATE OR REPLACE FUNCTION has_before (a timeperiod, b timeperiod)
    RETURNS boolean
    LANGUAGE SQL
    IMMUTABLE
    AS $$
    SELECT
        snd (a) < fst (b)
        OR snd (b) < fst (a);
$$ SET search_path = 'temporal_relationships';
--
-- [meets] [meets^-1]
--
-- no shared time tick.
--
-- [meets A E]
--  A   |-----|
--  E         |-----|
--
-- [meets^-1 A E]
--  A         |-----|
--  E   |-----|
--
CREATE OR REPLACE FUNCTION is_meets (a timeperiod, b timeperiod)
    RETURNS boolean
    LANGUAGE SQL
    IMMUTABLE
    AS $$
    SELECT
        snd (a) = fst (b);
$$ SET search_path = 'temporal_relationships';
CREATE OR REPLACE FUNCTION has_meets (a timeperiod, b timeperiod)
    RETURNS boolean
    LANGUAGE SQL
    IMMUTABLE
    AS $$
    SELECT
        snd (a) = fst (b)
        OR snd (b) = fst (a);
$$ SET search_path = 'temporal_relationships';
--
-- Partition of Allen Relationships
--
--
-- [Includes]
--     [Contains] or [Overlaps]
CREATE OR REPLACE FUNCTION has_includes (a timeperiod, b timeperiod)
    RETURNS boolean
    LANGUAGE SQL
    IMMUTABLE
    AS $$
    SELECT
        fst (a) = fst (b)
        OR snd (a) = snd (b)
        OR (snd (a) <= snd (b)
            AND (fst (a) >= fst (b)
                OR fst (b) < snd (a)))
        OR (snd (a) >= snd (b)
            AND (fst (a) < snd (b)
                OR fst (a) <= fst (b)));
$$ SET search_path = 'temporal_relationships';
--
-- [Contains]
--    [Encloses] or [Equals]
CREATE OR REPLACE FUNCTION has_contains (a timeperiod, b timeperiod)
    RETURNS boolean
    LANGUAGE SQL
    IMMUTABLE
    AS $$
    SELECT
        fst (a) = fst (b)
        OR snd (a) = snd (b)
        OR (snd (a) < snd (b)
            AND fst (a) > fst (b))
        OR (snd (b) < snd (a)
            AND fst (b) > fst (a));
$$ SET search_path = 'temporal_relationships';
--
-- [Aligns With]
--   [Starts] or [Finishes]
--
CREATE OR REPLACE FUNCTION has_aligns_with (a timeperiod, b timeperiod)
    RETURNS boolean
    LANGUAGE SQL
    IMMUTABLE
    AS $$
    SELECT
        XOR (fst (a) = fst (b),
            snd (a) = snd (b));
$$ SET search_path = 'temporal_relationships';
--
-- [Encloses]
--   [Aligns With] or [During]
--
CREATE OR REPLACE FUNCTION has_encloses (a timeperiod, b timeperiod)
    RETURNS boolean
    LANGUAGE SQL
    IMMUTABLE
    AS $$
    SELECT
        has_during (a, b)
        OR has_aligns_with (a, b);
$$ SET search_path = 'temporal_relationships';
--
-- [Excludes]
--   [Before] or [Meets]
--
CREATE OR REPLACE FUNCTION has_excludes (a timeperiod, b timeperiod)
    RETURNS boolean
    LANGUAGE SQL
    IMMUTABLE
    AS $$
    SELECT
        fst (a) >= snd (b)
        OR fst (b) >= snd (a);
$$ SET search_path = 'temporal_relationships';
COMMIT;

-- vim: set filetype=pgsql expandtab tabstop=2 shiftwidth=2:
