package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"strconv"
	"strings"
	"time"

	executions "cloud.google.com/go/workflows/executions/apiv1"
	"cloud.google.com/go/workflows/executions/apiv1/executionspb"
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

// WorkflowInput represents the data structure sent to the workflow
type WorkflowInput struct {
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
	Location           string
	WorkflowName       string
	WorkflowNameField  string
	ServiceAccountPath string
	TimeoutSeconds     int
	Source             string
	WaitForCompletion  bool
}

func main() {
	log.Println("Starting GCP Workflows executor...")

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

	// Determine the workflow name
	workflowName, err := resolveWorkflowName(config, alertData)
	if err != nil {
		log.Fatalf("Failed to resolve workflow name: %v", err)
	}

	log.Printf("Resolved workflow name: %s", workflowName)

	// Build input payload
	input := buildWorkflowInput(alertData, config.Source)

	// Execute workflow
	if err := executeWorkflow(config, workflowName, input); err != nil {
		log.Fatalf("Failed to execute workflow: %v", err)
	}

	log.Println("Workflow execution completed successfully")
}

func loadConfig() (*Config, error) {
	config := &Config{
		ProjectID:          os.Getenv("GCP_PROJECT_ID"),
		Location:           os.Getenv("GCP_LOCATION"),
		WorkflowName:       os.Getenv("WORKFLOW_NAME"),
		WorkflowNameField:  os.Getenv("WORKFLOW_NAME_FIELD"),
		ServiceAccountPath: os.Getenv("GOOGLE_APPLICATION_CREDENTIALS"),
		TimeoutSeconds:     300, // default 5 minutes
		Source:             "karo",
		WaitForCompletion:  true,
	}

	// Validate required fields
	if config.ProjectID == "" {
		return nil, fmt.Errorf("GCP_PROJECT_ID environment variable is required")
	}
	if config.Location == "" {
		config.Location = "us-central1" // default location
		log.Printf("GCP_LOCATION not specified, using default: %s", config.Location)
	}

	// Validate workflow name configuration
	if config.WorkflowName == "" && config.WorkflowNameField == "" {
		return nil, fmt.Errorf("either WORKFLOW_NAME (static) or WORKFLOW_NAME_FIELD (from alert) must be specified")
	}
	if config.WorkflowName != "" && config.WorkflowNameField != "" {
		return nil, fmt.Errorf("WORKFLOW_NAME and WORKFLOW_NAME_FIELD are mutually exclusive, specify only one")
	}

	// Parse optional timeout
	if timeoutStr := os.Getenv("TIMEOUT_SECONDS"); timeoutStr != "" {
		if timeout, err := strconv.Atoi(timeoutStr); err == nil {
			config.TimeoutSeconds = timeout
		}
	}

	// Override source if provided
	if source := os.Getenv("WORKFLOW_SOURCE"); source != "" {
		config.Source = source
	}

	// Parse wait for completion flag
	if waitStr := os.Getenv("WAIT_FOR_COMPLETION"); waitStr != "" {
		if wait, err := strconv.ParseBool(waitStr); err == nil {
			config.WaitForCompletion = wait
		}
	}

	log.Printf("Configuration loaded - Project: %s, Location: %s, Timeout: %ds, Wait: %t",
		config.ProjectID, config.Location, config.TimeoutSeconds, config.WaitForCompletion)

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

func resolveWorkflowName(config *Config, alert *AlertData) (string, error) {
	// If static workflow name is provided, use it
	if config.WorkflowName != "" {
		return config.WorkflowName, nil
	}

	// Extract workflow name from alert field
	if config.WorkflowNameField == "" {
		return "", fmt.Errorf("WORKFLOW_NAME_FIELD not specified")
	}

	var workflowName string

	// Try to get from parsed alert data first
	if alert != nil {
		workflowName = extractFieldFromAlert(alert, config.WorkflowNameField)
	}

	// If not found in parsed alert, try environment variables
	if workflowName == "" {
		workflowName = extractFieldFromEnv(config.WorkflowNameField)
	}

	if workflowName == "" {
		return "", fmt.Errorf("workflow name not found in alert field '%s'", config.WorkflowNameField)
	}

	// Sanitize workflow name (must match GCP naming requirements)
	workflowName = sanitizeWorkflowName(workflowName)

	if workflowName == "" {
		return "", fmt.Errorf("workflow name from field '%s' is invalid after sanitization", config.WorkflowNameField)
	}

	return workflowName, nil
}

func extractFieldFromAlert(alert *AlertData, fieldPath string) string {
	// Support dot notation for nested fields
	// Examples: "labels.workflow", "annotations.workflow_name", "status"
	parts := strings.Split(fieldPath, ".")

	if len(parts) == 1 {
		// Direct field access
		switch parts[0] {
		case "status":
			return alert.Status
		}
		return ""
	}

	if len(parts) == 2 {
		switch parts[0] {
		case "labels":
			if alert.Labels != nil {
				return alert.Labels[parts[1]]
			}
		case "annotations":
			if alert.Annotations != nil {
				return alert.Annotations[parts[1]]
			}
		}
	}

	return ""
}

func extractFieldFromEnv(fieldPath string) string {
	// Map common field paths to environment variables
	envMappings := map[string]string{
		"labels.alertname":          "ALERT_NAME",
		"labels.workflow":           "WORKFLOW_FROM_LABEL",
		"annotations.workflow":      "WORKFLOW_FROM_ANNOTATION",
		"annotations.workflow_name": "WORKFLOW_NAME_FROM_ANNOTATION",
		"status":                    "ALERT_STATUS",
	}

	if envVar, exists := envMappings[fieldPath]; exists {
		return os.Getenv(envVar)
	}

	// Try direct environment variable lookup
	// Convert field path to uppercase env var name
	envVarName := strings.ToUpper(strings.ReplaceAll(fieldPath, ".", "_"))
	return os.Getenv(envVarName)
}

func sanitizeWorkflowName(name string) string {
	// GCP Workflow names must match ^[a-zA-Z_][a-zA-Z0-9_-]*$
	// Convert to lowercase and replace invalid characters
	name = strings.ToLower(name)
	name = strings.ReplaceAll(name, " ", "-")
	name = strings.ReplaceAll(name, ".", "-")

	// Remove any characters that aren't alphanumeric, underscore, or hyphen
	var result strings.Builder
	for _, r := range name {
		if (r >= 'a' && r <= 'z') || (r >= '0' && r <= '9') || r == '_' || r == '-' {
			result.WriteRune(r)
		}
	}

	sanitized := result.String()

	// Ensure it starts with a letter or underscore
	if len(sanitized) > 0 && sanitized[0] >= '0' && sanitized[0] <= '9' {
		sanitized = "_" + sanitized
	}

	// Trim to maximum length (GCP limit is 63 characters)
	if len(sanitized) > 63 {
		sanitized = sanitized[:63]
	}

	return sanitized
}

func buildWorkflowInput(alert *AlertData, source string) *WorkflowInput {
	input := &WorkflowInput{
		Source:    source,
		Timestamp: time.Now().UTC().Format(time.RFC3339),
	}

	// If we have parsed alert data, use it
	if alert != nil {
		input.Status = alert.Status
		input.Labels = alert.Labels
		input.Annotations = alert.Annotations

		if alert.Labels != nil {
			input.AlertName = alert.Labels["alertname"]
			input.Severity = alert.Labels["severity"]
			input.Instance = alert.Labels["instance"]
		}

		if alert.Annotations != nil {
			input.Summary = alert.Annotations["summary"]
			input.Description = alert.Annotations["description"]
		}
	}

	// Use environment variable fallbacks
	if input.AlertName == "" {
		input.AlertName = os.Getenv("ALERT_NAME")
	}
	if input.Status == "" {
		input.Status = os.Getenv("ALERT_STATUS")
	}
	if input.Severity == "" {
		input.Severity = os.Getenv("ALERT_SEVERITY")
	}
	if input.Instance == "" {
		input.Instance = os.Getenv("INSTANCE")
	}
	if input.Summary == "" {
		input.Summary = os.Getenv("ALERT_SUMMARY")
	}
	if input.Description == "" {
		input.Description = os.Getenv("ALERT_DESCRIPTION")
	}

	return input
}

func executeWorkflow(config *Config, workflowName string, input *WorkflowInput) error {
	ctx, cancel := context.WithTimeout(context.Background(), time.Duration(config.TimeoutSeconds)*time.Second)
	defer cancel()

	// Create client options
	var clientOptions []option.ClientOption
	if config.ServiceAccountPath != "" {
		clientOptions = append(clientOptions, option.WithCredentialsFile(config.ServiceAccountPath))
	}
	// If no service account file is provided, the client will use Application Default Credentials

	// Create Workflows client
	client, err := executions.NewClient(ctx, clientOptions...)
	if err != nil {
		return fmt.Errorf("failed to create Workflows client: %w", err)
	}
	defer client.Close()

	// Convert input to JSON
	inputData, err := json.Marshal(input)
	if err != nil {
		return fmt.Errorf("failed to marshal workflow input: %w", err)
	}

	log.Printf("Executing workflow '%s' with input: %s", workflowName, string(inputData))

	// Construct the workflow path
	workflowPath := fmt.Sprintf("projects/%s/locations/%s/workflows/%s", config.ProjectID, config.Location, workflowName)

	// Create execution request
	req := &executionspb.CreateExecutionRequest{
		Parent: workflowPath,
		Execution: &executionspb.Execution{
			Argument: string(inputData),
		},
	}

	// Execute workflow
	execution, err := client.CreateExecution(ctx, req)
	if err != nil {
		return fmt.Errorf("failed to create workflow execution: %w", err)
	}

	log.Printf("Workflow execution created: %s", execution.Name)

	// If configured to wait for completion, poll for result
	if config.WaitForCompletion {
		return waitForExecution(ctx, client, execution.Name)
	}

	log.Println("Workflow execution started successfully (not waiting for completion)")
	return nil
}

func waitForExecution(ctx context.Context, client *executions.Client, executionName string) error {
	log.Println("Waiting for workflow execution to complete...")

	ticker := time.NewTicker(5 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return fmt.Errorf("timeout waiting for workflow execution to complete")
		case <-ticker.C:
			// Get execution status
			req := &executionspb.GetExecutionRequest{
				Name: executionName,
			}

			execution, err := client.GetExecution(ctx, req)
			if err != nil {
				return fmt.Errorf("failed to get execution status: %w", err)
			}

			log.Printf("Execution state: %s", execution.State.String())

			switch execution.State {
			case executionspb.Execution_SUCCEEDED:
				log.Println("Workflow execution completed successfully")
				if execution.Result != "" {
					log.Printf("Execution result: %s", execution.Result)
				}
				return nil
			case executionspb.Execution_FAILED:
				log.Printf("Workflow execution failed: %s", execution.Error.GetPayload())
				return fmt.Errorf("workflow execution failed: %s", execution.Error.GetPayload())
			case executionspb.Execution_CANCELLED:
				return fmt.Errorf("workflow execution was cancelled")
			case executionspb.Execution_ACTIVE:
				// Continue polling
				continue
			default:
				log.Printf("Unknown execution state: %s", execution.State.String())
				continue
			}
		}
	}
}
