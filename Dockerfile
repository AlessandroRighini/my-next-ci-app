# 1. Fase di build
FROM node:20-alpine AS builder

WORKDIR /app

# Copio solo i file di dependency per velocizzare la cache
COPY package*.json ./
# Se usi pnpm/yarn, adatta questa riga
RUN npm install

# Copio il resto del codice
COPY . .

# Build del progetto (Next.js)
RUN npm run build

# 2. Fase runtime: immagine più leggera
FROM node:20-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production

# Copio solo ciò che serve per run
COPY --from=builder /app/package*.json ./
RUN npm install --omit=dev

COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/next.config.mjs ./next.config.mjs

EXPOSE 3000

CMD ["npm", "start"]
