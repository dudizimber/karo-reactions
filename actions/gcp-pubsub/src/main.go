package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"strconv"
	"time"

	"cloud.google.com/go/pubsub/v2"
	"google.golang.org/api/option"
)

// AlertData represents the structure of alert information
type AlertData struct {
	Status      string            `json:"status"`
	Labels      map[string]string `json:"labels"`
	Annotations map[string]string `json:"annotations"`
	StartsAt    string            `json:"startsAt,omitempty"`
	EndsAt      string            `json:"endsAt,omitempty"`
}

// PubSubMessage represents the message structure sent to Pub/Sub
type PubSubMessage struct {
	AlertName   string            `json:"alertName"`
	Status      string            `json:"status"`
	Severity    string            `json:"severity"`
	Instance    string            `json:"instance"`
	Summary     string            `json:"summary"`
	Description string            `json:"description"`
	Labels      map[string]string `json:"labels"`
	Annotations map[string]string `json:"annotations"`
	Timestamp   string            `json:"timestamp"`
	Source      string            `json:"source"`
}

type Config struct {
	ProjectID          string
	TopicID            string
	ServiceAccountPath string
	TimeoutSeconds     int
	Source             string
}

func main() {
	log.Println("Starting GCP Pub/Sub publisher...")

	// Load configuration
	config, err := loadConfig()
	if err != nil {
		log.Fatalf("Configuration error: %v", err)
	}

	// Parse alert data
	alertData, err := parseAlertData()
	if err != nil {
		log.Printf("Warning: Failed to parse alert data: %v", err)
	}

	// Build message payload
	message := buildMessage(alertData, config.Source)

	// Publish to Pub/Sub
	if err := publishMessage(config, message); err != nil {
		log.Fatalf("Failed to publish message: %v", err)
	}

	log.Println("Message published successfully to Pub/Sub")
}

func loadConfig() (*Config, error) {
	config := &Config{
		ProjectID:          os.Getenv("GCP_PROJECT_ID"),
		TopicID:            os.Getenv("PUBSUB_TOPIC_ID"),
		ServiceAccountPath: os.Getenv("GOOGLE_APPLICATION_CREDENTIALS"),
		TimeoutSeconds:     30, // default
		Source:             "karo",
	}

	// Validate required fields
	if config.ProjectID == "" {
		return nil, fmt.Errorf("GCP_PROJECT_ID environment variable is required")
	}
	if config.TopicID == "" {
		return nil, fmt.Errorf("PUBSUB_TOPIC_ID environment variable is required")
	}

	// Parse optional timeout
	if timeoutStr := os.Getenv("TIMEOUT_SECONDS"); timeoutStr != "" {
		if timeout, err := strconv.Atoi(timeoutStr); err == nil {
			config.TimeoutSeconds = timeout
		}
	}

	// Override source if provided
	if source := os.Getenv("MESSAGE_SOURCE"); source != "" {
		config.Source = source
	}

	log.Printf("Configuration loaded - Project: %s, Topic: %s, Timeout: %ds",
		config.ProjectID, config.TopicID, config.TimeoutSeconds)

	return config, nil
}

func parseAlertData() (*AlertData, error) {
	alertJSON := os.Getenv("ALERT_JSON")
	if alertJSON == "" {
		log.Println("No ALERT_JSON provided, using individual environment variables")
		return nil, nil
	}

	var alertData AlertData
	if err := json.Unmarshal([]byte(alertJSON), &alertData); err != nil {
		return nil, fmt.Errorf("failed to parse ALERT_JSON: %w", err)
	}

	return &alertData, nil
}

func buildMessage(alert *AlertData, source string) *PubSubMessage {
	message := &PubSubMessage{
		Source:    source,
		Timestamp: time.Now().UTC().Format(time.RFC3339),
	}

	// If we have parsed alert data, use it
	if alert != nil {
		message.Status = alert.Status
		message.Labels = alert.Labels
		message.Annotations = alert.Annotations

		if alert.Labels != nil {
			message.AlertName = alert.Labels["alertname"]
			message.Severity = alert.Labels["severity"]
			message.Instance = alert.Labels["instance"]
		}

		if alert.Annotations != nil {
			message.Summary = alert.Annotations["summary"]
			message.Description = alert.Annotations["description"]
		}
	}

	// Use environment variable fallbacks
	if message.AlertName == "" {
		message.AlertName = os.Getenv("ALERT_NAME")
	}
	if message.Status == "" {
		message.Status = os.Getenv("ALERT_STATUS")
	}
	if message.Severity == "" {
		message.Severity = os.Getenv("ALERT_SEVERITY")
	}
	if message.Instance == "" {
		message.Instance = os.Getenv("INSTANCE")
	}
	if message.Summary == "" {
		message.Summary = os.Getenv("ALERT_SUMMARY")
	}
	if message.Description == "" {
		message.Description = os.Getenv("ALERT_DESCRIPTION")
	}

	return message
}

func publishMessage(config *Config, message *PubSubMessage) error {
	ctx, cancel := context.WithTimeout(context.Background(), time.Duration(config.TimeoutSeconds)*time.Second)
	defer cancel()

	// Create client options
	var clientOptions []option.ClientOption
	if config.ServiceAccountPath != "" {
		clientOptions = append(clientOptions, option.WithCredentialsFile(config.ServiceAccountPath))
	}
	// If no service account file is provided, the client will use Application Default Credentials

	// Create Pub/Sub client
	client, err := pubsub.NewClient(ctx, config.ProjectID, clientOptions...)
	if err != nil {
		return fmt.Errorf("failed to create Pub/Sub client: %w", err)
	}
	defer client.Close()

	// Get topic reference
	publisher := client.Publisher(config.TopicID)

	// Convert message to JSON
	messageData, err := json.Marshal(message)
	if err != nil {
		return fmt.Errorf("failed to marshal message: %w", err)
	}

	log.Printf("Publishing message to topic %s: %s", config.TopicID, string(messageData))

	// Create Pub/Sub message
	pubsubMsg := &pubsub.Message{
		Data: messageData,
		Attributes: map[string]string{
			"alertName": message.AlertName,
			"status":    message.Status,
			"severity":  message.Severity,
			"source":    message.Source,
			"timestamp": message.Timestamp,
		},
	}

	// Publish message
	result := publisher.Publish(ctx, pubsubMsg)

	// Wait for the result
	messageID, err := result.Get(ctx)
	if err != nil {
		return fmt.Errorf("failed to publish message: %w", err)
	}

	log.Printf("Message published successfully with ID: %s", messageID)
	return nil
}
