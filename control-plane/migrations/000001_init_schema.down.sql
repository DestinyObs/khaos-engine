-- Drop triggers
DROP TRIGGER IF EXISTS update_experiments_updated_at ON experiments;

-- Drop function
DROP FUNCTION IF EXISTS update_updated_at_column();

-- Drop tables
DROP TABLE IF EXISTS audit_logs;
DROP TABLE IF EXISTS experiment_runs;
DROP TABLE IF EXISTS experiments;
