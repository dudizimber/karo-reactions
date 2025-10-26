# Build stage
FROM golang:1.24-alpine AS builder

LABEL org.opencontainers.image.title="Karo: Webhook Sender"
LABEL org.opencontainers.image.description="Sends alert data to HTTP webhooks"
LABEL org.opencontainers.image.source="https://github.com/dudizimber/karo-reactions"
LABEL org.opencontainers.image.vendor="dudizimber"

WORKDIR /app

# Copy go mod files
COPY src/go.mod src/go.sum* ./

# Download dependencies
RUN go mod download

# Copy source code
COPY src/ .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags='-w -s -extldflags "-static"' \
    -o webhook-sender .

# Runtime stage
FROM alpine:3.18

# Install ca-certificates for HTTPS requests
RUN apk --no-cache add ca-certificates tzdata

# Create non-root user
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

WORKDIR /app

# Copy binary from builder stage
COPY --from=builder /app/webhook-sender .

# Change ownership to non-root user
RUN chown -R appuser:appgroup /app

# Switch to non-root user
USER appuser

# Set timezone
ENV TZ=UTC

ENTRYPOINT ["./webhook-sender"]