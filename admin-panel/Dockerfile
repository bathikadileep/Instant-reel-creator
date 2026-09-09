# ==============================================================================
# Multi-Stage Production Dockerfile for Instant Reel Admin Panel (React + Vite)
# ==============================================================================

# ------------------------------------------------------------------------------
# Stage 1: Build static assets
# ------------------------------------------------------------------------------
FROM node:20-alpine AS builder

WORKDIR /app

# Cache dependencies
COPY package.json package-lock.json ./
RUN npm ci

# Copy source and build
COPY . .

# Build-time environment arguments (can be overridden via Docker build args)
ARG VITE_API_BASE_URL=https://instant-reel-api.onrender.com/api/v1
ENV VITE_API_BASE_URL=$VITE_API_BASE_URL

RUN npm run build

# ------------------------------------------------------------------------------
# Stage 2: Production Nginx web server
# ------------------------------------------------------------------------------
FROM nginx:1.27-alpine AS runner

# Remove default nginx html and configs
RUN rm -rf /usr/share/nginx/html/* /etc/nginx/conf.d/default.conf

# Copy custom production nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy compiled static distribution from builder
COPY --from=builder /app/dist /usr/share/nginx/html

# Expose HTTP port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
