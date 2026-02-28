# Node.js Docker Best Practices

When containerizing a Node.js application, ensure you follow these best practices for performance, security, and developer experience.

## Dockerfile Example

```dockerfile
# Use a specific, slim, and deterministic base image
FROM node:20.11.1-alpine AS base
# Set the working directory
WORKDIR /app
# Install dependencies needed for node-gyp if necessary
# RUN apk add --no-cache python3 make g++

FROM base AS deps
COPY package.json package-lock.json ./
# Use clean install for deterministic builds
RUN npm ci

FROM base AS builder
COPY --from=deps /app/node_modules ./node_modules
COPY . .
# If building a TypeScript project or a framework like Next.js:
# RUN npm run build

FROM base AS runner
# Set node environment
ENV NODE_ENV=production

# Run as non-root user for security
# alpine comes with a 'node' user
USER node

# Copy only necessary files from builder
COPY --from=builder --chown=node:node /app/package.json ./
# If TS/compiled, copy dist
# COPY --from=builder --chown=node:node /app/dist ./dist
# If running directly (e.g., Express)
COPY --from=builder --chown=node:node /app/node_modules ./node_modules
COPY --from=builder --chown=node:node /app/src ./src

# Expose the application port
EXPOSE 3000

# Use dumb-init or similar if process signals are an issue, 
# but for modern node it's often fine to run node directly if you handle SIGINT/SIGTERM.
CMD ["node", "src/index.js"]
```

## Key Guidelines
1. **Use `npm ci` instead of `npm install`**: Ensures reproducible builds by strictly following `package-lock.json`.
2. **Multi-Stage Builds**: Keep the final image small by omitting devDependencies and build tools.
3. **Non-Root User**: Always switch to the `node` user in the final stage (`USER node`).
4. **Alpine or Slim**: Prefer `alpine` or `slim` tags to minimize attack surface and image size.
5. **Node Env**: Set `NODE_ENV=production` explicitly. Some frameworks heavily optimize based on this variable.
6. **Graceful Shutdown**: Ensure your Node.js application handles `SIGTERM` and `SIGINT` to shut down gracefully within Docker.
