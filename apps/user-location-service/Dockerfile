# Multi-stage Dockerfile
FROM node:22-alpine AS builder

WORKDIR /usr/src/app

# Copy package manifests
COPY package.json package-lock.json ./
COPY nest-cli.json tsconfig.json tsconfig.build.json ./

# Install only production dependencies to reduce image size
RUN npm ci --only=production && npm cache clean --force

# Copy source code
COPY . .

# Build the service
RUN npm install --no-save && npm run build user-location-service && npm prune --production

# Runtime image
FROM node:22-alpine
WORKDIR /usr/src/app

# Copy only the built artifacts and production node_modules
COPY --from=builder /usr/src/app/dist ./dist
COPY --from=builder /usr/src/app/node_modules ./node_modules

# Expose port
EXPOSE 3004

# Production environment
ENV NODE_ENV=production

# Add user for security
RUN addgroup -g 1001 -S nodejs && adduser -S nestjs -u 1001 -G nodejs
USER nestjs

# App start
CMD ["node", "dist/apps/user-location-service/main"]