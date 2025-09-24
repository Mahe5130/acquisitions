# ---- base ----
FROM node:20-alpine AS base
WORKDIR /usr/src/app
# Create non-root user once and reuse
RUN addgroup -g 1001 -S nodejs && adduser -S nodejs -u 1001
COPY package*.json ./

# ---- development ----
FROM base AS development
ENV NODE_ENV=development
# Install ALL deps (incl. devDependencies) for hot-reload tools (vite/nodemon/etc.)
RUN npm ci
# Bring in the full app for dev
# Bring in the full app for dev with correct ownership
COPY --chown=nodejs:nodejs . .
# Ensure logs dir exists and is writable
RUN mkdir -p /usr/src/app/logs && chown -R nodejs:nodejs /usr/src/app
USER nodejs
# Expose typical dev ports (adjust to your app – keep both if you run Vite + API)
EXPOSE 5173
EXPOSE 3002
# Expect you have "dev" script (e.g. nodemon/vite). Otherwise change this to your actual dev command
# CMD ["npm", "run", "dev"]
# Dev entrypoint (guarantee logs/ exists at runtime too)
CMD ["sh", "-c", "mkdir -p /usr/src/app/logs && npm run dev"]

# ---- build (optional, only if you have a build step) ----
FROM base AS build
ENV NODE_ENV=production
RUN npm ci
COPY . .
# If you have a build step (e.g. transpile/bundle), do it here:
# RUN npm run build

# ---- production ----
FROM node:20-alpine AS production
WORKDIR /usr/src/app    
ENV NODE_ENV=production
# Copy from build stage (or from base if no build output artifacts)
COPY --from=build /usr/src/app ./
# If you truly have no build step, you can replace the above with:
# COPY . .
# RUN npm ci --only=production && npm cache clean --force
RUN addgroup -g 1001 -S nodejs && adduser -S nodejs -u 1001
USER nodejs
EXPOSE 3002
CMD ["node", "src/index.js"]
