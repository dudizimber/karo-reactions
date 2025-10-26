package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strconv"
	"time"
)

// AlertData represents the structure of alert information
type AlertData struct {
	Status      string            `json:"status"`
	Labels      map[string]string `json:"labels"`
	Annotations map[string]string `json:"annotations"`
	StartsAt    string            `json:"startsAt,omitempty"`
	EndsAt      string            `json:"endsAt,omitempty"`
}

// WebhookPayload represents the payload sent to the webhook
type WebhookPayload struct {
	AlertName   string            `json:"alertName"`
	Status      string            `json:"status"`
	Severity    string            `json:"severity"`
	Instance    string            `json:"instance"`
	Summary     string            `json:"summary"`
	Description string            `json:"description"`
	Labels      map[string]string `json:"labels"`
	Annotations map[string]string `json:"annotations"`
	Timestamp   string            `json:"timestamp"`
}

func main() {
	log.Println("Starting webhook sender...")

	// Get configuration from environment variables
	webhookURL := os.Getenv("WEBHOOK_URL")
	if webhookURL == "" {
		log.Fatal("WEBHOOK_URL environment variable is required")
	}

	timeoutStr := os.Getenv("TIMEOUT_SECONDS")
	timeout := 30 // default timeout
	if timeoutStr != "" {
		if t, err := strconv.Atoi(timeoutStr); err == nil {
			timeout = t
		}
	}

	// Parse alert data
	alertJSON := os.Getenv("ALERT_JSON")
	var alertData AlertData

	if alertJSON != "" {
		if err := json.Unmarshal([]byte(alertJSON), &alertData); err != nil {
			log.Printf("Warning: Failed to parse ALERT_JSON: %v", err)
		}
	}

	// Build webhook payload
	payload := buildWebhookPayload(alertData)

	// Send webhook
	if err := sendWebhook(webhookURL, payload, timeout); err != nil {
		log.Fatalf("Failed to send webhook: %v", err)
	}

	log.Println("Webhook sent successfully")
}

func buildWebhookPayload(alert AlertData) WebhookPayload {
	payload := WebhookPayload{
		Status:      alert.Status,
		Labels:      alert.Labels,
		Annotations: alert.Annotations,
		Timestamp:   time.Now().UTC().Format(time.RFC3339),
	}

	// Extract common fields with fallbacks to environment variables
	if alert.Labels != nil {
		payload.AlertName = getValueWithFallback(alert.Labels["alertname"], os.Getenv("ALERT_NAME"))
		payload.Severity = getValueWithFallback(alert.Labels["severity"], os.Getenv("ALERT_SEVERITY"))
		payload.Instance = getValueWithFallback(alert.Labels["instance"], os.Getenv("INSTANCE"))
	} else {
		payload.AlertName = os.Getenv("ALERT_NAME")
		payload.Severity = os.Getenv("ALERT_SEVERITY")
		payload.Instance = os.Getenv("INSTANCE")
	}

	if alert.Annotations != nil {
		payload.Summary = getValueWithFallback(alert.Annotations["summary"], os.Getenv("ALERT_SUMMARY"))
		payload.Description = getValueWithFallback(alert.Annotations["description"], os.Getenv("ALERT_DESCRIPTION"))
	} else {
		payload.Summary = os.Getenv("ALERT_SUMMARY")
		payload.Description = os.Getenv("ALERT_DESCRIPTION")
	}

	// Use environment variable fallback for status if not in alert data
	if payload.Status == "" {
		payload.Status = os.Getenv("ALERT_STATUS")
	}

	return payload
}

func getValueWithFallback(primary, fallback string) string {
	if primary != "" {
		return primary
	}
	return fallback
}

func sendWebhook(url string, payload WebhookPayload, timeoutSeconds int) error {
	// Convert payload to JSON
	jsonData, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("failed to marshal payload: %w", err)
	}

	log.Printf("Sending webhook to: %s", url)
	log.Printf("Payload: %s", string(jsonData))

	// Create HTTP client with timeout
	client := &http.Client{
		Timeout: time.Duration(timeoutSeconds) * time.Second,
	}

	// Create request
	req, err := http.NewRequest("POST", url, bytes.NewBuffer(jsonData))
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}

	// Set headers
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("User-Agent", "karo-webhook-sender/1.0.0")

	// Add custom headers from environment variables
	if authHeader := os.Getenv("AUTH_HEADER"); authHeader != "" {
		req.Header.Set("Authorization", authHeader)
	}

	// Send request
	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	// Read response body
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		log.Printf("Warning: Failed to read response body: %v", err)
	}

	log.Printf("Response status: %s", resp.Status)
	if len(body) > 0 {
		log.Printf("Response body: %s", string(body))
	}

	// Check if request was successful
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return fmt.Errorf("webhook request failed with status %d: %s", resp.StatusCode, string(body))
	}

	return nil
}
