-- Runs automatically ONCE: the first time the postgres container starts
-- with an EMPTY data volume. Connected to the database named in POSTGRES_DB (dataco).

CREATE SCHEMA IF NOT EXISTS bronze;
CREATE SCHEMA IF NOT EXISTS silver;
CREATE SCHEMA IF NOT EXISTS gold;
CREATE SCHEMA IF NOT EXISTS ml;
CREATE SCHEMA IF NOT EXISTS meta;

COMMENT ON SCHEMA bronze IS 'Raw CSV data loaded as-is, plus _loaded_at and _batch_id';
COMMENT ON SCHEMA silver IS 'Cleaned, typed, tested tables built by dbt';
COMMENT ON SCHEMA gold   IS 'Star schema and feature tables built by dbt';
COMMENT ON SCHEMA ml     IS 'Model predictions and monitoring results';
COMMENT ON SCHEMA meta   IS 'Pipeline bookkeeping such as load_log';
