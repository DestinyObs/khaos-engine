package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

var (
	httpRequestsTotal = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "http_requests_total",
			Help: "Total number of HTTP requests",
		},
		[]string{"method", "endpoint", "status"},
	)

	httpRequestDuration = prometheus.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "http_request_duration_seconds",
			Help:    "Duration of HTTP requests in seconds",
			Buckets: prometheus.DefBuckets,
		},
		[]string{"method", "endpoint"},
	)
)

func init() {
	prometheus.MustRegister(httpRequestsTotal)
	prometheus.MustRegister(httpRequestDuration)
}

func main() {
	hostname, _ := os.Hostname()
	port := getEnv("PORT", "8080")

	http.HandleFunc("/", handleHome(hostname))
	http.HandleFunc("/health", handleHealth)
	http.Handle("/metrics", promhttp.Handler())

	log.Printf("ChaosCraft Demo App starting on port %s (pod: %s)", port, hostname)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatal(err)
	}
}

func handleHome(hostname string) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()

		w.Header().Set("Content-Type", "text/html; charset=utf-8")
		w.WriteHeader(http.StatusOK)

		html := fmt.Sprintf(`
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ChaosCraft Demo</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%%, #764ba2 100%%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }

        .container {
            background: rgba(255, 255, 255, 0.95);
            border-radius: 20px;
            padding: 60px 40px;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
            max-width: 600px;
            width: 100%%;
            text-align: center;
        }

        .logo {
            font-size: 72px;
            margin-bottom: 20px;
            animation: float 3s ease-in-out infinite;
        }

        @keyframes float {
            0%%, 100%% { transform: translateY(0px); }
            50%% { transform: translateY(-10px); }
        }

        h1 {
            color: #2d3748;
            font-size: 42px;
            margin-bottom: 10px;
            font-weight: 700;
        }

        .subtitle {
            color: #667eea;
            font-size: 20px;
            margin-bottom: 40px;
            font-weight: 500;
        }

        .info-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
            margin-top: 40px;
        }

        .info-card {
            background: linear-gradient(135deg, #667eea 0%%, #764ba2 100%%);
            padding: 20px;
            border-radius: 12px;
            color: white;
        }

        .info-label {
            font-size: 12px;
            text-transform: uppercase;
            letter-spacing: 1px;
            opacity: 0.9;
            margin-bottom: 8px;
            font-weight: 600;
        }

        .info-value {
            font-size: 16px;
            font-weight: 700;
            word-break: break-all;
        }

        .status {
            display: inline-block;
            background: #48bb78;
            color: white;
            padding: 8px 20px;
            border-radius: 20px;
            font-size: 14px;
            font-weight: 600;
            margin-top: 30px;
        }

        .status::before {
            content: "●";
            margin-right: 8px;
            animation: pulse 2s ease-in-out infinite;
        }

        @keyframes pulse {
            0%%, 100%% { opacity: 1; }
            50%% { opacity: 0.5; }
        }

        .footer {
            margin-top: 40px;
            padding-top: 30px;
            border-top: 2px solid #e2e8f0;
            color: #718096;
            font-size: 14px;
        }

        .footer a {
            color: #667eea;
            text-decoration: none;
            font-weight: 600;
        }

        .footer a:hover {
            text-decoration: underline;
        }

        @media (max-width: 600px) {
            .container {
                padding: 40px 20px;
            }
            h1 {
                font-size: 32px;
            }
            .info-grid {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="logo">🔥</div>
        <h1>ChaosCraft</h1>
        <div class="subtitle">Chaos Engineering Platform</div>
        
        <div class="info-grid">
            <div class="info-card">
                <div class="info-label">Pod Name</div>
                <div class="info-value">%s</div>
            </div>
            <div class="info-card">
                <div class="info-label">Timestamp</div>
                <div class="info-value">%s</div>
            </div>
            <div class="info-card">
                <div class="info-label">Request Method</div>
                <div class="info-value">%s</div>
            </div>
            <div class="info-card">
                <div class="info-label">User Agent</div>
                <div class="info-value">%s</div>
            </div>
        </div>

        <div class="status">HEALTHY</div>

        <div class="footer">
            <strong>Endpoints:</strong><br>
            <a href="/">/</a> • 
            <a href="/health">/health</a> • 
            <a href="/metrics">/metrics</a>
        </div>
    </div>
</body>
</html>
`, hostname, time.Now().Format("15:04:05 MST"), r.Method, r.UserAgent())

		fmt.Fprint(w, html)

		duration := time.Since(start).Seconds()
		httpRequestDuration.WithLabelValues(r.Method, r.URL.Path).Observe(duration)
		httpRequestsTotal.WithLabelValues(r.Method, r.URL.Path, "200").Inc()
	}
}

func handleHealth(w http.ResponseWriter, r *http.Request) {
	start := time.Now()

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	fmt.Fprintf(w, `{"status":"healthy","timestamp":"%s"}`, time.Now().Format(time.RFC3339))

	duration := time.Since(start).Seconds()
	httpRequestDuration.WithLabelValues(r.Method, r.URL.Path).Observe(duration)
	httpRequestsTotal.WithLabelValues(r.Method, r.URL.Path, "200").Inc()
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
