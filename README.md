## Panoramica

Questo progetto è un esempio minimale di Continuous Integration (CI) basato su:

- Next.js con React e TypeScript
- Docker con build multi-stage ottimizzata
- GitHub Actions per automatizzare lint, build e build Docker
- Configurazione compatibile con ambienti Windows, Linux e macOS

L'obiettivo è avere una pipeline CI affidabile che verifichi:

- ✔️ installazione dipendenze (`npm ci`)
- ✔️ lint (`npm run lint`)
- ✔️ build Next.js (`npm run build`)
- ✔️ build immagine Docker (senza deploy, per ora)

---

## 🚀 1. Creazione del progetto

L’app è stata generata tramite:

```bash
npx create-next-app@latest my-next-ci-app --typescript
```

La struttura è quella standard di Next.js + TypeScript.

Per avviare l’app in sviluppo:

```bash
npm run dev
```

Poi visita [http://localhost:3000](http://localhost:3000).

---

## 🐙 2. Inizializzazione Git e repository GitHub

```bash
git init
git add .
git commit -m "Initial Next.js + TS app"
git remote add origin https://github.com/<user>/<repo>.git
git branch -M main
git push -u origin main
```

---

## 🐳 3. Dockerfile (multi-stage build)

Abbiamo creato un Dockerfile multi-stage per produrre un'immagine ottimizzata e priva di dev-dependencies.

### 🔧 Nota importante sulla configurazione di Next.js

Il file `next.config.ts` è stato convertito in `next.config.mjs`. Questo evita che il runtime Docker richieda il pacchetto `typescript` nella fase finale, mantenendo l'immagine pulita.

### Dockerfile

```Dockerfile
# 1. Build stage
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .
RUN npm run build

# 2. Runtime stage
FROM node:20-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production

COPY --from=builder /app/package*.json ./
RUN npm install --omit=dev

COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/next.config.mjs ./next.config.mjs

EXPOSE 3000

CMD ["npm", "start"]
```

Per provarlo in locale:

```bash
docker build -t my-next-ci-app .
docker run -p 3000:3000 my-next-ci-app
```

---

## 🔄 4. Continuous Integration con GitHub Actions

La CI è configurata per eseguire:

1. Checkout del repository
2. Setup Node.js (v20) con cache npm
3. Installazione dipendenze (`npm ci`)
4. Lint (`npm run lint`)
5. Build Next.js (`npm run build`)
6. Build Docker (senza push)

### Workflow (`.github/workflows/ci.yml`)

```yaml
name: CI

on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]

jobs:
  build-and-test:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: "20"
          cache: "npm"

      - name: Install dependencies
        run: npm ci

      - name: Lint
        run: npm run lint

      # Abilita se hai test:
      # - name: Test
      #   run: npm test

      - name: Build Next.js app
        run: npm run build

  docker-build:
    runs-on: ubuntu-latest
    needs: build-and-test

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Set up QEMU
        uses: docker/setup-qemu-action@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Build Docker image
        uses: docker/build-push-action@v6
        with:
          context: .
          push: false
          tags: my-next-ci-app:test
```

### 📍 Cosa fa la CI?

| Step                    | Descrizione                                            |
| ----------------------- | ------------------------------------------------------ |
| `npm ci`                | Installazione pulita e riproducibile delle dipendenze  |
| `npm run lint`          | Analisi statica del codice                             |
| `npm run build`         | Compilazione Next.js                                   |
| `docker/build-push-action` | Costruzione immagine Docker in ambiente CI         |

---

## 📝 5. Stato attuale del progetto

La pipeline CI fornisce:

- ✔️ Verifica qualità del codice
- ✔️ Build Next.js
- ✔️ Build immagine Docker
- ✔️ Controllo automatico su ogni push e pull request

Prossimi step possibili:

1. Ottimizzazione cache Docker e npm
2. Aggiunta di test automatizzati
3. Push automatico dell'immagine su GHCR/DockerHub
4. Pipeline CD per il deploy

---

## 📄 6. Comandi principali

- Avvio sviluppo: `npm run dev`
- Build produzione: `npm run build`
- Avvio in produzione (dopo build): `npm start`
- Build immagine Docker: `docker build -t my-next-ci-app .`

---

## 📚 Risorse utili

- [Documentazione Next.js](https://nextjs.org/docs)
- [Documentazione Docker](https://docs.docker.com/)
- [GitHub Actions](https://docs.github.com/actions)

Se vuoi espandere la pipeline (test E2E, deploy automatico, ecc.) puoi partire dalle sezioni sopra e integrare i passi che servono.
