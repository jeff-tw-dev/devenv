# Python (FastAPI/Flask) Docker Best Practices

When containerizing a Python application, follow these guidelines to optimize size and security.

## Dockerfile Example

```dockerfile
# Use a specific, slim, deterministic base image
FROM python:3.11-slim-bookworm AS builder

# Set environment variables for Python
ENV PYTHONDONTWRITEBYTECODE=1 
    PYTHONUNBUFFERED=1

# Install required build tools
RUN apt-get update && apt-get install -y --no-install-recommends gcc 
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Upgrade pip and install poetry or pipenv if used, or stick to pip
RUN pip install --upgrade pip

# Copy only requirements to cache them in docker layer
COPY requirements.txt .

# Install dependencies to the local user directory (eg. ~/.local)
RUN pip install --user -r requirements.txt

# Final stage
FROM python:3.11-slim-bookworm AS runner

# Set environment variables again
ENV PYTHONDONTWRITEBYTECODE=1 
    PYTHONUNBUFFERED=1

# Add user pip directory to PATH
ENV PATH="/home/appuser/.local/bin:${PATH}"

# Create an unprivileged user to run the app
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Switch to the non-root user
USER appuser

# Set working directory
WORKDIR /app

# Copy the dependencies from builder
COPY --from=builder --chown=appuser:appuser /root/.local /home/appuser/.local

# Copy application code
COPY --chown=appuser:appuser . /app

# Expose port
EXPOSE 8000

# Start the application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

## Key Guidelines
1. **Multi-Stage Builds**: Build dependencies in one stage and copy them (e.g., using `--user` to `~/.local` or using a `venv`) to the final stage.
2. **Non-Root User**: Always create a non-root user (e.g., `appuser`) and switch to it.
3. **Slim Base Image**: Use `python:<version>-slim` to balance small size and compatibility. Alpine can sometimes be tricky with Python C-extensions (like numpy or psycopg2).
4. **Environment Variables**:
   - `PYTHONDONTWRITEBYTECODE=1`: Keeps Python from generating `.pyc` files in the container.
   - `PYTHONUNBUFFERED=1`: Ensures that output is sent straight to the terminal without being buffered, crucial for logs.
5. **No Cache**: If not using multi-stage builds, use `--no-cache-dir` with pip to prevent caching the installation files in the image.
