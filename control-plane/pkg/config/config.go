package config

import (
	"fmt"
	"os"
	"strconv"
)

// Config holds application configuration
type Config struct {
	Environment string
	Port        int
	DatabaseURL string
	LogLevel    string
	GRPCPort    int
}

// Load loads configuration from environment variables
func Load() (*Config, error) {
	cfg := &Config{
		Environment: getEnv("ENVIRONMENT", "development"),
		Port:        getEnvAsInt("PORT", 8080),
		DatabaseURL: getEnv("DATABASE_URL", "postgres://chaoscraft:chaoscraft@localhost:5432/chaoscraft?sslmode=disable"),
		LogLevel:    getEnv("LOG_LEVEL", "info"),
		GRPCPort:    getEnvAsInt("GRPC_PORT", 9090),
	}

	// Validate configuration
	if cfg.DatabaseURL == "" {
		return nil, fmt.Errorf("DATABASE_URL is required")
	}

	return cfg, nil
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func getEnvAsInt(key string, defaultValue int) int {
	if value := os.Getenv(key); value != "" {
		if intVal, err := strconv.Atoi(value); err == nil {
			return intVal
		}
	}
	return defaultValue
}
