package storage

import (
	"context"
	"database/sql"
	"fmt"

	"github.com/golang-migrate/migrate/v4"
	"github.com/golang-migrate/migrate/v4/database/postgres"
	_ "github.com/golang-migrate/migrate/v4/source/file"
	_ "github.com/lib/pq"
	"go.uber.org/zap"
)

// Store defines the interface for data persistence
type Store interface {
	// Health check
	Ping(ctx context.Context) error
	
	// Close connection
	Close() error
	
	// Run migrations
	Migrate() error
}

// PostgresStore implements Store interface using PostgreSQL
type PostgresStore struct {
	db     *sql.DB
	logger *zap.Logger
}

// NewPostgresStore creates a new PostgreSQL store
func NewPostgresStore(databaseURL string, logger *zap.Logger) (*PostgresStore, error) {
	db, err := sql.Open("postgres", databaseURL)
	if err != nil {
		return nil, fmt.Errorf("failed to open database: %w", err)
	}

	// Configure connection pool
	db.SetMaxOpenConns(25)
	db.SetMaxIdleConns(5)

	// Test connection
	if err := db.Ping(); err != nil {
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	logger.Info("connected to PostgreSQL database")

	return &PostgresStore{
		db:     db,
		logger: logger,
	}, nil
}

// Ping checks database connectivity
func (s *PostgresStore) Ping(ctx context.Context) error {
	return s.db.PingContext(ctx)
}

// Close closes the database connection
func (s *PostgresStore) Close() error {
	if s.db != nil {
		s.logger.Info("closing database connection")
		return s.db.Close()
	}
	return nil
}

// Migrate runs database migrations
func (s *PostgresStore) Migrate() error {
	driver, err := postgres.WithInstance(s.db, &postgres.Config{})
	if err != nil {
		return fmt.Errorf("failed to create migration driver: %w", err)
	}

	m, err := migrate.NewWithDatabaseInstance(
		"file://migrations",
		"postgres",
		driver,
	)
	if err != nil {
		return fmt.Errorf("failed to create migrate instance: %w", err)
	}

	if err := m.Up(); err != nil && err != migrate.ErrNoChange {
		return fmt.Errorf("failed to run migrations: %w", err)
	}

	s.logger.Info("database migrations completed successfully")
	return nil
}
