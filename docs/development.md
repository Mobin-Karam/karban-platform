# Local development

Karban contains independent backend, mobile, admin, and website applications. They share an HTTP API contract but are not managed as one package-manager workspace.

## Prerequisites

- Node.js 22+
- PostgreSQL 16+
- npm
- Docker / Docker Compose (optional, recommended for the fastest multi-service start)
- Rust + Android/iOS toolchains only when building native Tauri targets

## Fastest start with Docker

From the repository root:

```bash
docker compose up --build
```

This starts:

- PostgreSQL on `localhost:5432`
- API on `http://localhost:4000/api/v1`
- Admin on `http://localhost:5174`
- Website on `http://localhost:3001`

The mobile client is run separately.

## Backend without Docker

Start PostgreSQL first, then:

```bash
cp backend/.env.example backend/.env
cd backend
npm ci
npx prisma generate
npx prisma validate
npm run prisma:deploy
npm run prisma:seed
npm run dev
```

The repository already contains a committed initial migration. Use `prisma migrate dev` only when intentionally creating a new development migration.

## Mobile

```bash
cd mobile
cp .env.example .env
npm ci
npm run dev
```

For native Android work, install the Rust/Tauri and Android prerequisites, then use:

```bash
npm run tauri:android:init
npm run tauri:android:dev
```

## Admin

```bash
cd admin
cp .env.example .env
npm ci
npm run dev
```

## Website

```bash
cd website
cp .env.example .env.local
npm ci
npm run dev
```

## Default ports

| Surface | Port |
| --- | ---: |
| API | 4000 |
| Mobile Vite | 5173 |
| Admin | 5174 |
| Website | 3001 |
| PostgreSQL | 5432 |

## Quality checks

Run the checks appropriate to each changed application. A fuller checklist is maintained in [`BUILD_AUDIT.md`](BUILD_AUDIT.md).
