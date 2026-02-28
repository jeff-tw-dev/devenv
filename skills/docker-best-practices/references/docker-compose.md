# Docker Compose Best Practices

When writing a `docker-compose.yml` for local development or simple deployments, structure it for maintainability, clarity, and security.

## docker-compose.yml Example

```yaml
services:
  app:
    build:
      context: .
      # Target a specific stage in a multi-stage build (e.g. dev, prod)
      target: dev
    container_name: my-node-app
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=development
      # Use an env_file to manage sensitive credentials or large numbers of variables
    env_file:
      - .env
    volumes:
      # Bind mount the current directory for live-reloading
      - .:/app
      # Create an anonymous volume to prevent local node_modules from overriding container node_modules
      - /app/node_modules
    depends_on:
      db:
        # Wait for the DB to be healthy, not just started
        condition: service_healthy
    networks:
      - app-network

  db:
    image: postgres:15-alpine
    container_name: my-postgres-db
    environment:
      # Pass database credentials via a secure mechanism
      POSTGRES_USER: ${POSTGRES_USER:-postgres}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-postgres}
      POSTGRES_DB: ${POSTGRES_DB:-myapp}
    volumes:
      - db-data:/var/lib/postgresql/data
    networks:
      - app-network
    # Expose locally for debugging, use mapped port if port conflict arises
    ports:
      - "5432:5432"
    # A healthcheck ensures the DB is genuinely ready for connections
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-postgres} -d ${POSTGRES_DB:-myapp}"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  # Named volumes for persistent data
  db-data:

networks:
  # Define a custom bridge network for the app stack
  app-network:
    driver: bridge
```

## Key Guidelines
1. **Use `depends_on` with `condition: service_healthy`**: Ensure dependencies (like databases or message queues) are fully ready to accept connections before the application starts.
2. **Environment Variables**: Prefer `.env` files for secrets or large lists of variables, rather than hardcoding them in `docker-compose.yml`. Use default fallbacks (`${VAR:-default}`) to prevent startup failures if an environment variable is omitted.
3. **Volumes**:
   - Use named volumes (`db-data:`) for stateful services (databases, caches) to persist data across container restarts.
   - For Node.js/Python development, use bind mounts to reflect local code changes but consider anonymous volumes to isolate dependencies (e.g., `/app/node_modules`).
4. **Networks**: Define a custom bridge network (`app-network`) instead of relying on the default bridge. It improves isolation and allows services to communicate securely by container name.
5. **Target Specific Build Stages**: If using multi-stage builds, target the `dev` stage during development to include development tools (like nodemon, live-reload), but default to the production runner in CI.
