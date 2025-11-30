package main

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/chaoscraft/control-plane/pkg/api"
	"github.com/chaoscraft/control-plane/pkg/config"
	"github.com/chaoscraft/control-plane/pkg/storage"
	"github.com/gin-gonic/gin"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"go.uber.org/zap"
)

const (
	serviceName    = "chaoscraft-control-plane"
	serviceVersion = "0.1.0"
)

func main() {
	// Initialize logger
	logger, err := zap.NewProduction()
	if err != nil {
		fmt.Fprintf(os.Stderr, "failed to initialize logger: %v\n", err)
		os.Exit(1)
	}
	defer logger.Sync()

	logger.Info("starting control plane",
		zap.String("service", serviceName),
		zap.String("version", serviceVersion),
	)

	// Load configuration
	cfg, err := config.Load()
	if err != nil {
		logger.Fatal("failed to load configuration", zap.Error(err))
	}

	// Initialize storage
	store, err := storage.NewPostgresStore(cfg.DatabaseURL, logger)
	if err != nil {
		logger.Fatal("failed to initialize storage", zap.Error(err))
	}
	defer store.Close()

	// Run migrations
	if err := store.Migrate(); err != nil {
		logger.Fatal("failed to run migrations", zap.Error(err))
	}

	// Initialize Gin router
	if cfg.Environment == "production" {
		gin.SetMode(gin.ReleaseMode)
	}

	router := gin.New()
	router.Use(gin.Recovery())
	router.Use(api.LoggerMiddleware(logger))
	router.Use(api.CORSMiddleware())

	// Health check endpoints
	router.GET("/health", healthHandler)
	router.GET("/ready", readyHandler(store))

	// Metrics endpoint
	router.GET("/metrics", gin.WrapH(promhttp.Handler()))

	// API v1 routes
	v1 := router.Group("/api/v1")
	{
		// Experiments
		experiments := v1.Group("/experiments")
		{
			experiments.GET("", api.ListExperiments(store, logger))
			experiments.POST("", api.CreateExperiment(store, logger))
			experiments.GET("/:id", api.GetExperiment(store, logger))
			experiments.DELETE("/:id", api.DeleteExperiment(store, logger))
			experiments.POST("/:id/start", api.StartExperiment(store, logger))
			experiments.POST("/:id/stop", api.StopExperiment(store, logger))
		}

		// System info
		v1.GET("/version", versionHandler)
	}

	// Create HTTP server
	srv := &http.Server{
		Addr:         fmt.Sprintf(":%d", cfg.Port),
		Handler:      router,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// Start server in goroutine
	go func() {
		logger.Info("starting HTTP server",
			zap.Int("port", cfg.Port),
		)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Fatal("failed to start server", zap.Error(err))
		}
	}()

	// Wait for interrupt signal
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	logger.Info("shutting down server...")

	// Graceful shutdown with timeout
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		logger.Fatal("server forced to shutdown", zap.Error(err))
	}

	logger.Info("server stopped gracefully")
}

func healthHandler(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status":  "healthy",
		"service": serviceName,
		"version": serviceVersion,
	})
}

func readyHandler(store storage.Store) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Check database connection
		if err := store.Ping(c.Request.Context()); err != nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{
				"status": "not ready",
				"error":  "database connection failed",
			})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"status":  "ready",
			"service": serviceName,
			"version": serviceVersion,
		})
	}
}

func versionHandler(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"service": serviceName,
		"version": serviceVersion,
		"go_version": os.Getenv("GO_VERSION"),
	})
}
