# HR Portal Backend Dockerfile
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install --omit=dev

# Copy source code
COPY src ./src

# Production image
FROM node:18-alpine

# Create non-root user (use GID/UID that don't conflict with base image)
RUN addgroup -g 1001 nodeapp && adduser -u 1001 -G nodeapp -s /bin/sh -D nodeapp

WORKDIR /app

# Copy from builder
COPY --from=builder --chown=nodeapp:nodeapp /app /app

# Switch to non-root user
USER nodeapp

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Start application
CMD ["node", "src/index.js"]
