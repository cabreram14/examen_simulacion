# --- Etapa 1: instalar dependencias y correr las pruebas (fail fast) ---
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm test

# --- Etapa 2: imagen final, minima, solo lo necesario para ejecutar ---
FROM node:20-alpine AS runtime
WORKDIR /app
ARG APP_VERSION=v3-roto
ARG APP_COLOR=red
ARG SIMULATE_FAILURE=true
ENV NODE_ENV=production
ENV APP_VERSION=$APP_VERSION
ENV APP_COLOR=$APP_COLOR
ENV SIMULATE_FAILURE=$SIMULATE_FAILURE
# El proceso escuchará realmente en 8080
ENV PORT=8080
COPY package*.json ./
RUN npm ci --omit=dev
COPY --from=build /app/server.js ./server.js
USER node
# ERROR INTENCIONAL: Docker indica 3000
# EXPOSE 3000

# CORRECCION: Docker indica 8080
EXPOSE 8080
# ERROR INTENCIONAL: consulta 3000, pero Node escucha en 8080
# HEALTHCHECK --interval=10s --timeout=3s CMD node -e "require('http').get('http://localhost:3000/health', r => process.exit(r.statusCode === 200 ? 0 : 1)).on('error', () => process.exit(1))"
# CMD ["node", "server.js"]

#CORRECCION: consulta 8080, que es donde Node escucha
HEALTHCHECK --interval=10s --timeout=3s CMD node -e "require('http').get('http://localhost:8080/health', r => process.exit(r.statusCode === 200 ? 0 : 1)).on('error', () => process.exit(1))"
CMD ["node", "server.js"]