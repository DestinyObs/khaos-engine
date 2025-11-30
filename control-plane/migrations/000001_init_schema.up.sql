-- Create experiments table
CREATE TABLE IF NOT EXISTS experiments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    spec JSONB NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_by VARCHAR(255),
    namespace VARCHAR(255),
    labels JSONB DEFAULT '{}'::jsonb
);

-- Create index on status for faster queries
CREATE INDEX idx_experiments_status ON experiments(status);

-- Create index on created_at for time-based queries
CREATE INDEX idx_experiments_created_at ON experiments(created_at DESC);

-- Create index on namespace for multi-tenant queries
CREATE INDEX idx_experiments_namespace ON experiments(namespace);

-- Create experiment_runs table for tracking execution history
CREATE TABLE IF NOT EXISTS experiment_runs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    experiment_id UUID NOT NULL REFERENCES experiments(id) ON DELETE CASCADE,
    run_number INTEGER NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'running',
    started_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP WITH TIME ZONE,
    result JSONB,
    error_message TEXT,
    rollback_triggered BOOLEAN DEFAULT FALSE,
    blast_radius_score DECIMAL(5,2),
    UNIQUE(experiment_id, run_number)
);

-- Create index on experiment_id for faster lookups
CREATE INDEX idx_experiment_runs_experiment_id ON experiment_runs(experiment_id);

-- Create audit_logs table for tracking all actions
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    user_id VARCHAR(255),
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(100) NOT NULL,
    resource_id VARCHAR(255),
    details JSONB,
    ip_address INET,
    user_agent TEXT
);

-- Create index on timestamp for time-based queries
CREATE INDEX idx_audit_logs_timestamp ON audit_logs(timestamp DESC);

-- Create index on resource for tracking specific resources
CREATE INDEX idx_audit_logs_resource ON audit_logs(resource_type, resource_id);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for experiments table
CREATE TRIGGER update_experiments_updated_at
    BEFORE UPDATE ON experiments
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
