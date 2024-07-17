package main

import (
	"fmt"
	"net/http"
	"os"
	"time"
)

const (
	latencyThreshold = 500 // Latency threshold in milliseconds
)

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Usage: go run api_latency_monitor.go <api_url>")
		os.Exit(1)
	}

	apiURL := os.Args[1]
	err := monitorAPILatency(apiURL)
	if err != nil {
		fmt.Printf("Error monitoring API latency: %v\n", err)
		os.Exit(1)
	}
}

func monitorAPILatency(apiURL string) error {
	client := &http.Client{}

	for {
		startTime := time.Now()
		resp, err := client.Get(apiURL)
		if err != nil {
			return err
		}
		defer resp.Body.Close()

		latency := time.Since(startTime).Milliseconds()

		fmt.Printf("API Latency for %s: %d ms\n", apiURL, latency)

		if latency > latencyThreshold {
			fmt.Printf("Warning: API latency exceeds the threshold of %d ms\n", latencyThreshold)
		}

		time.Sleep(5 * time.Second) // Wait for 5 seconds before the next check
	}
}
