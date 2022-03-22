BEGIN;
SET local search_path TO public;
CREATE EXTENSION IF NOT EXISTS btree_gist;
COMMIT;

