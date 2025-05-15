# Multi-stage Dockerfile
FROM node:20-alpine AS builder

WORKDIR /usr/src/app

# Copy package manifests
COPY package.json package-lock.json ./

# Install dependencies
RUN npm ci

# Copy source code
COPY . .

# Build the service
RUN npm run build authorities-service

# Runtime image
FROM node:20-alpine
WORKDIR /usr/src/app

# Copy built artifacts and dependencies
COPY --from=builder /usr/src/app/dist ./dist
COPY --from=builder /usr/src/app/node_modules ./node_modules

# Expose port
EXPOSE 3006

# Production environment
ENV NODE_ENV=production

# App start
CMD ["node", "dist/apps/authorities-service/main"]