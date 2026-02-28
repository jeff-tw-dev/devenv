---
name: docker-best-practices
description: Containerize development environments using Docker best practices. Use when creating or optimizing Dockerfiles or docker-compose.yml files for web applications, APIs, or services.
---

# Docker Best Practices

## Overview

This skill provides guidelines and templates for containerizing applications using Docker. It ensures resulting images are secure, small, fast to build, and easy to maintain. It also includes best practices for creating robust `docker-compose.yml` configurations for local development.

## Core Containerization Guidelines

When building or reviewing a Dockerfile or Docker Compose configuration, always adhere to these core principles:

1. **Use Specific, Deterministic Base Images**
   - Never use the `latest` tag. Always pin to a specific version (e.g., `node:20.11.1-alpine`).
   - Prefer `alpine` or `slim` variants (e.g., `python:3.11-slim-bookworm`) to minimize the image footprint and attack surface.
   - For statically compiled languages (like Go or Rust), use `scratch` as the final base image.

2. **Leverage Multi-Stage Builds**
   - Separate the build environment (compilers, dev dependencies, build tools) from the runtime environment.
   - The final image should only contain the compiled artifact or the source code and production dependencies required to run the application.

3. **Run as a Non-Root User**
   - For security, never run applications as the `root` user within the container.
   - Create a dedicated user and group (e.g., `appuser` or `node`) and switch to it using the `USER` directive before the `CMD` or `ENTRYPOINT`.

4. **Optimize Layer Caching**
   - Order your `Dockerfile` instructions from the least frequently changed to the most frequently changed.
   - Copy dependency manifests (e.g., `package.json`, `requirements.txt`, `go.mod`) and install dependencies *before* copying the application source code. This allows Docker to cache the dependency installation layer.

5. **Minimize Image Size and Attack Surface**
   - Do not install unnecessary packages (e.g., `vim`, `curl`) in the final image.
   - Use `--no-install-recommends` with `apt-get` or `--no-cache` with `apk`.
   - Clean up package manager caches in the same `RUN` layer (e.g., `rm -rf /var/lib/apt/lists/*`).

6. **Environment Configuration**
   - Set environment variables explicitly for production behavior (e.g., `NODE_ENV=production`, `PYTHONDONTWRITEBYTECODE=1`).
   - In `docker-compose.yml`, prefer using `.env` files for secrets and configuration, and provide fallback defaults (`${VAR:-default}`).

7. **Healthchecks and Dependencies**
   - Define a `healthcheck` for services in `docker-compose.yml` to verify they are ready to accept connections (not just running).
   - Use `depends_on` with `condition: service_healthy` to ensure dependent services wait for upstream services to become healthy before starting.

## Framework-Specific References

For specific languages and frameworks, refer to the detailed guidelines:

- **Node.js (Express, Next.js, etc.)**: See [references/node-express.md](references/node-express.md)
- **Python (FastAPI, Flask, Django)**: See [references/python-fastapi.md](references/python-fastapi.md)
- **Go (Static Binaries)**: See [references/go-service.md](references/go-service.md)
- **Docker Compose (Local Dev & Services)**: See [references/docker-compose.md](references/docker-compose.md)
