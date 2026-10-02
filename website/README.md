# Karban Public Website

The Karban website is the Persian public-facing surface for product marketing, business discovery, and server-rendered business profiles.

It is built with Next.js and consumes public Karban API endpoints rather than duplicating marketplace data in the website codebase.

## What it includes

- Persian marketing homepage
- Verified-business directory
- Public business profile pages
- Search/discovery-oriented server rendering
- Per-page metadata
- `LocalBusiness` structured data
- Sitemap and robots configuration
- Privacy and terms routes
- eNamad placement component
- Reserved product screenshot/video showcase areas

## Stack

- Next.js 16
- React 19
- TypeScript
- Lucide icons

## Local development

```bash
cd website
cp .env.example .env.local
npm ci
npm run dev
```

Default URL: `http://localhost:3001`.

Environment:

```env
NEXT_PUBLIC_SITE_URL=http://localhost:3001
NEXT_PUBLIC_API_URL=http://localhost:4000/api/v1
```

Run the backend first or use the repository root Compose workspace.

## Build

```bash
npm run typecheck
npm run build
npm run start
```

## SEO / discoverability

Public business pages are designed to expose useful metadata and structured business information to search engines and answer engines. Keep business name, location, services, verification state, and other public data sourced from the API so search output does not drift from the product.

## Screenshot and video showcase

The website currently keeps **intentional placeholders** for product screenshots and promotional video. This is preferable to shipping invented product imagery.

When release media is available, replace the placeholders with captures from a real running Karban build and keep the assets optimized for the web. The root repository README follows the same rule: source-backed claims first, real product media second.

## eNamad note

The eNamad component should only be published with credentials/markup that belong to the production legal entity. Re-check the merchant identifier and current eNamad requirements before a production launch.
