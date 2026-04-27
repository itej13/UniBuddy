# UniBuddy

UniBuddy tracks college attendance and Google Classroom submissions in one place — a full-stack web app built with Next.js, deployed on Vercel, backed by Supabase (PostgreSQL).

## Features

- Google Sign-In for college accounts
- Google Classroom sync for courses, coursework, due dates, and submission state
- Subject setup with name, code, credits, and optional Classroom course linking
- Timetable builder with weekly class slots
- Attendance logging per subject and date
- Dashboard summaries for today's classes, pending submissions, and attendance percentages

## Stack

- **Framework:** Next.js 16 (App Router, React Server Components)
- **Auth:** NextAuth v5 with Google OAuth (database sessions)
- **Database:** Supabase (PostgreSQL) via Prisma ORM
- **Deployment:** Vercel
- **Styling:** Tailwind CSS v4

## Requirements

- Node.js 18+
- A Google Cloud project with:
  - Google Classroom API enabled
  - OAuth 2.0 Web Application credentials

## Local Development

```bash
cd web
cp .env.example .env.local
# Fill in AUTH_GOOGLE_ID, AUTH_GOOGLE_SECRET, AUTH_SECRET, AUTH_URL, DATABASE_URL, DIRECT_URL
npm install
npm run dev
```

Open `http://localhost:3000`.

## Environment Variables

| Variable | Description |
|---|---|
| `AUTH_GOOGLE_ID` | Google OAuth Web client ID |
| `AUTH_GOOGLE_SECRET` | Google OAuth Web client secret |
| `AUTH_SECRET` | Random secret for session encryption (`openssl rand -base64 32`) |
| `AUTH_URL` | Base URL (`http://localhost:3000` locally, Vercel URL in production) |
| `DATABASE_URL` | Supabase pooler URL (port 6543, `?pgbouncer=true&connection_limit=1`) |
| `DIRECT_URL` | Supabase direct URL (port 5432, used for migrations only) |

## Google Cloud Setup

1. Enable the **Google Classroom API**
2. Create an OAuth 2.0 credential — type: **Web application**
3. Add authorized redirect URI: `https://your-app.vercel.app/api/auth/callback/google`
4. Add authorized JavaScript origin: `https://your-app.vercel.app`

## Privacy & Security

- Sessions are database-backed — no tokens embedded in cookies
- Google access tokens stored server-side only, never sent to the browser
- All data queries are scoped by `userId` — students can only access their own data
- HTTP security headers: CSP, HSTS, X-Frame-Options, X-Content-Type-Options
- Google Classroom scopes are read-only
