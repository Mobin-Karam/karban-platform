# Local development

## Prerequisites

- Node.js 22+
- PostgreSQL 16+
- npm
- Rust + Android/iOS toolchains only when building native Tauri targets

## Bootstrap API

```bash
cp backend/.env.example backend/.env
docker compose up -d postgres
cd backend
npm install
npx prisma generate
npx prisma migrate dev --name init
npm run prisma:seed
npm run dev
```

## Mobile

```bash
cd mobile
cp .env.example .env
npm install
npm run dev
# Native after Rust/Tauri prerequisites:
npm run tauri android init
npm run tauri android dev
```

## Admin

```bash
cd admin
cp .env.example .env
npm install
npm run dev
```

## Website

```bash
cd website
cp .env.example .env.local
npm install
npm run dev
```

Default ports: API 3000, mobile Vite 5173, admin 5174, website 3001.
