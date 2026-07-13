<div align="center">

# UniBuddy

**The all-in-one academic companion for college students.**  
Track attendance, monitor submissions, and sync your Google Classroom — all in one place.

[![Next.js](https://img.shields.io/badge/Next.js_15-black?style=for-the-badge&logo=next.js&logoColor=white)](https://nextjs.org)
[![TypeScript](https://img.shields.io/badge/TypeScript-3178C6?style=for-the-badge&logo=typescript&logoColor=white)](https://www.typescriptlang.org)
[![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)
[![Vercel](https://img.shields.io/badge/Vercel-000000?style=for-the-badge&logo=vercel&logoColor=white)](https://vercel.com)
[![Tailwind CSS](https://img.shields.io/badge/Tailwind_CSS_v4-06B6D4?style=for-the-badge&logo=tailwindcss&logoColor=white)](https://tailwindcss.com)
[![CI](https://github.com/itej13/UniBuddy/actions/workflows/ci.yml/badge.svg)](https://github.com/itej13/UniBuddy/actions/workflows/ci.yml)

[**Live Demo →**](https://uni-buddy-kappa.vercel.app)

</div>

---

## What it does

UniBuddy pulls your courses and assignments straight from Google Classroom and gives you a clean dashboard to manage everything that actually matters in college — without juggling five different apps.

| | |
|---|---|
| **Dashboard** | Today's classes, pending submissions, and attendance percentages at a glance |
| **Timetable** | Build your weekly schedule with multi-day class slots |
| **Attendance** | Log and track attendance per subject with percentage summaries |
| **Subjects** | Set up subjects with credits, codes, and link them to Classroom courses |
| **Submissions** | See all pending and submitted coursework with due dates |
| **Settings** | Manage your account and trigger a Classroom sync |

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Next.js 15 — App Router, React Server Components, Server Actions |
| Language | TypeScript 5 |
| Auth | NextAuth v5 — Google OAuth, database-backed sessions |
| Database | PostgreSQL via Supabase, managed with Prisma ORM |
| Styling | Tailwind CSS v4 |
| Deployment | Vercel (Edge + Serverless) |
| External API | Google Classroom API (read-only) |

---

## Architecture

```
Browser
  │
  ├─► middleware.ts     Lightweight session-cookie check before protected routes
  │
  ├─► /app/*            React Server Components — fetch data server-side
  │     └─► lib/data.ts        userId-scoped Prisma queries
  │     └─► lib/actions.ts     Server Actions, all guarded by requireUserId()
  │
  ├─► /api/auth/*       NextAuth v5 — Google OAuth callback, session management
  │
  └─► lib/classroom.ts  Google Classroom API — syncs courses & assignments
              │
    Supabase PostgreSQL (ap-south-1)
```

---

## Getting Started

### Prerequisites

- Node.js 18+
- A [Google Cloud](https://console.cloud.google.com) project with **Google Classroom API** enabled
- A [Supabase](https://supabase.com) project (free tier works)

### 1. Clone & install

```bash
git clone https://github.com/itej13/UniBuddy.git
cd UniBuddy/web
npm install
```

### 2. Configure environment

```bash
cp .env.example .env.local
```

Fill in `.env.local` — see the [Environment Variables](#environment-variables) section below.

### 3. Run

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000).

---

## Environment Variables

Create `web/.env.local` with the following:

| Variable | Description |
|---|---|
| `AUTH_GOOGLE_ID` | OAuth 2.0 Web Application client ID from Google Cloud Console |
| `AUTH_GOOGLE_SECRET` | OAuth 2.0 client secret |
| `AUTH_SECRET` | Random 32-byte secret — generate with `openssl rand -base64 32` |
| `AUTH_URL` | App base URL — `http://localhost:3000` for local dev |
| `DATABASE_URL` | Supabase **transaction pooler** URL (port 6543) |
| `DIRECT_URL` | Supabase **direct connection** URL (port 5432) — used for migrations only |

> **Never commit `.env.local`.** It is gitignored by default.

### Google Cloud Setup

1. Go to [APIs & Services → Credentials](https://console.cloud.google.com/apis/credentials)
2. Enable the **Google Classroom API**
3. Create an OAuth 2.0 credential — type: **Web application**
4. Add to **Authorized redirect URIs**:
   ```
   http://localhost:3000/api/auth/callback/google
   https://your-app.vercel.app/api/auth/callback/google
   ```
5. Add to **Authorized JavaScript origins**:
   ```
   http://localhost:3000
   https://your-app.vercel.app
   ```

### Supabase Setup

1. Create a project at [supabase.com](https://supabase.com)
2. Go to **Settings → Database → Connection string**
3. Copy the **Transaction** URL (port 6543) → `DATABASE_URL`
4. Copy the **Direct connection** URL (port 5432) → `DIRECT_URL`
5. Apply the schema: `npm run db:push`

---

## Project Structure

```
UniBuddy/
└── web/                        Next.js application
    ├── prisma/
    │   ├── schema.prisma       Database schema (PostgreSQL)
    │   └── migrations/         SQL migration history
    ├── src/
    │   ├── app/                Routes (App Router)
    │   │   ├── dashboard/
    │   │   ├── subjects/
    │   │   ├── timetable/
    │   │   ├── attendance/
    │   │   ├── submissions/
    │   │   ├── settings/
    │   │   └── api/auth/       NextAuth route handler
    │   ├── components/
    │   │   ├── app-shell.tsx   Navigation layout
    │   │   ├── auth-gate.tsx   Sign-in screen
    │   │   ├── views.tsx       Page-level view components
    │   │   └── ui.tsx          Shared UI primitives
    │   ├── lib/
    │   │   ├── actions.ts      Server Actions (CRUD + Classroom sync)
    │   │   ├── data.ts         Data fetching (userId-scoped)
    │   │   ├── classroom.ts    Google Classroom API client
    │   │   ├── domain.ts       Business logic utilities
    │   │   └── prisma.ts       Prisma client singleton
    │   ├── auth.ts             NextAuth v5 configuration
    │   └── middleware.ts        Route-level auth middleware
    ├── .env.example            Environment variable template
    └── next.config.ts          Security headers + Next.js config
```

---

## Database Scripts

```bash
npm run db:migrate      # Create and apply a new migration (development)
npm run db:migrate:prod # Apply pending migrations (production / CI)
npm run db:push         # Push schema changes without migration files
npm run db:studio       # Open Prisma Studio (visual DB browser)
```

## Quality Checks

GitHub Actions runs the same checks used before release on every push and pull request:

```bash
cd web
npm ci
npm run lint
npm run build
```

---

## Security

Student data privacy is a first-class concern. Here's how it's enforced:

- **Database-backed sessions** — session tokens are opaque references stored in PostgreSQL; no user data is embedded in cookies or JWTs
- **Server-side token storage** — Google OAuth access and refresh tokens never leave the server or appear in client-side state
- **Row-level data isolation** — every Prisma query includes `where: { userId }`, making cross-user data access impossible at the application layer
- **Route protection** — `middleware.ts` checks for a valid session cookie on every protected request; `requireUserId()` in Server Actions enforces auth a second time
- **Read-only Classroom scopes** — the app requests `classroom.courses.readonly`, `classroom.coursework.me.readonly`, and `classroom.student-submissions.me.readonly`; it cannot modify any Classroom data
- **HTTP security headers** — Content-Security-Policy, HSTS (2-year max-age), X-Frame-Options: DENY, X-Content-Type-Options: nosniff, Referrer-Policy, Permissions-Policy

---

## Deployment

The app deploys automatically on every push to `main` via Vercel.

To deploy manually:

```bash
npm exec --package=vercel -- vercel deploy --prod
```

Set all environment variables listed above in your Vercel project settings (**Settings → Environment Variables**).

---

## Contributing

1. Fork the repo
2. Create a branch: `git checkout -b feature/your-feature`
3. Make your changes and commit
4. Open a pull request against `main`

---

<div align="center">

Built by [Tejas Das](https://github.com/itej13)

</div>
