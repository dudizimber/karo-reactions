# Build stage
FROM golang:1.24-alpine AS builder

LABEL org.opencontainers.image.title="Alert Reaction: GCP Pub/Sub Publisher"
LABEL org.opencontainers.image.description="Publishes alert data to Google Cloud Pub/Sub topics"
LABEL org.opencontainers.image.source="https://github.com/dudizimber/alert-reactions"
LABEL org.opencontainers.image.vendor="dudizimber"

WORKDIR /app

# Install git (needed for Go modules)
RUN apk add --no-cache git

# Copy go mod files
COPY src/go.mod src/go.sum* ./

# Download dependencies
RUN go mod download

# Copy source code
COPY src/ .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags='-w -s -extldflags "-static"' \
    -o gcp-pubsub .

# Runtime stage
FROM alpine:3.18

# Install ca-certificates for HTTPS requests
RUN apk --no-cache add ca-certificates tzdata

# Create non-root user
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

WORKDIR /app

# Copy binary from builder stage
COPY --from=builder /app/gcp-pubsub .

# Change ownership to non-root user
RUN chown -R appuser:appgroup /app

# Switch to non-root user
USER appuser

# Set timezone
ENV TZ=UTC

ENTRYPOINT ["./gcp-pubsub"]