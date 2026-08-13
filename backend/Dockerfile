# syntax=docker/dockerfile:1

FROM node:20-alpine AS builder
WORKDIR /app
ENV PUPPETEER_SKIP_DOWNLOAD=true
RUN apk add --no-cache openssl
COPY package*.json ./
RUN npm ci --no-audit --no-fund
COPY prisma ./prisma
RUN ./node_modules/.bin/prisma generate
COPY tsconfig.json tsconfig.build.json nest-cli.json ./
COPY src ./src
RUN npm run build

FROM node:20-alpine AS production-deps
WORKDIR /app
ENV NODE_ENV=production \
    PUPPETEER_SKIP_DOWNLOAD=true
RUN apk add --no-cache openssl
COPY package*.json ./
COPY prisma ./prisma
RUN npm ci --omit=dev --no-audit --no-fund \
 && ./node_modules/.bin/prisma generate \
 && npm cache clean --force

FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production \
    PORT=4000 \
    HOST=0.0.0.0 \
    STORAGE_ROOT=/app/storage \
    PUPPETEER_SKIP_DOWNLOAD=true
RUN apk add --no-cache ca-certificates openssl wget \
 && addgroup -S appgroup \
 && adduser -S -D -H -u 1001 -G appgroup appuser
COPY --from=production-deps --chown=appuser:appgroup /app/node_modules ./node_modules
COPY --from=builder --chown=appuser:appgroup /app/dist ./dist
COPY --from=builder --chown=appuser:appgroup /app/prisma ./prisma
COPY --chown=appuser:appgroup docker/entrypoint.sh ./docker/entrypoint.sh
RUN mkdir -p /app/storage \
 && chmod +x /app/docker/entrypoint.sh \
 && chown -R appuser:appgroup /app/storage
USER appuser
EXPOSE 4000
CMD ["./docker/entrypoint.sh"]
