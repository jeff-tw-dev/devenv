# Go Docker Best Practices

When containerizing a Go application, leverage Go's capability to build static binaries to create extremely minimal Docker images.

## Dockerfile Example

```dockerfile
# Use a specific, official base image for building
FROM golang:1.22-alpine AS builder

# Set Go environment variables for static build
ENV CGO_ENABLED=0 
    GOOS=linux 
    GOARCH=amd64

# Install git or ca-certificates if your app needs them
RUN apk add --no-cache ca-certificates git

# Set the working directory
WORKDIR /app

# Download dependencies first to cache them as a separate layer
COPY go.mod go.sum ./
RUN go mod download

# Copy the source code
COPY . .

# Build the application statically
RUN go build -o /app/main .

# Build a scratch or minimal image for the final artifact
FROM scratch AS runner

# Import the user and group files from the builder
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/group /etc/group

# Import the root certificates
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Switch to the non-root user
USER nobody:nobody

# Copy the static binary
COPY --from=builder --chown=nobody:nobody /app/main /main

# Expose port
EXPOSE 8080

# Command to run
ENTRYPOINT ["/main"]
```

## Key Guidelines
1. **Multi-Stage Builds**: Compile the static binary in a fully featured `golang` image and copy only the final binary into a smaller image.
2. **Scratch Image**: The `FROM scratch` directive is perfect for statically compiled Go binaries. It provides an empty filesystem, maximizing security and minimizing size.
3. **CGO Disabled**: Set `CGO_ENABLED=0` to ensure the binary is statically linked and doesn't depend on C libraries (like glibc) present only on the builder image.
4. **Dependencies**: Copy `go.mod` and `go.sum` before copying source code. This allows Docker to cache the downloaded dependencies layer unless the `go.mod` changes.
5. **Certificates & Users**: When using a scratch image, you must explicitly copy `ca-certificates` if your app makes HTTPS requests, and explicitly copy `/etc/passwd` to run as a non-root user (e.g., `nobody`).
