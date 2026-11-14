# Multi-stage Dockerfile for ShadowDiff Cloud Deployment (Fly.io / Kubernetes)
FROM golang:1.22-alpine AS builder

WORKDIR /app

# Install build dependencies
RUN apk add --no-cache git ca-certificates

# Copy dependency manifests
COPY go.mod go.sum* ./
RUN go mod download || true

# Copy source
COPY . .

# Build the proxy engine binary
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /shadowdiff ./cmd/shadowdiff/main.go || \
    CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /shadowdiff ./main.go || true

# Production minimal runtime
FROM alpine:3.20

WORKDIR /app
RUN apk --no-cache add ca-certificates curl

# Copy binary from builder
COPY --from=builder /shadowdiff /app/shadowdiff

# Default environment variables
ENV PORT=8080 \
    SAFE_MODE_ONLY=false \
    FLOAT_TOLERANCE=0.000001 \
    GEMINI_MODEL=gemini-2.0-flash

EXPOSE 8080

HEALTHCHECK --interval=15s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:${PORT}/healthz || exit 1

ENTRYPOINT ["/app/shadowdiff"]
