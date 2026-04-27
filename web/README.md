# UniBuddy Web

Sibling Next.js web app for UniBuddy. It keeps the macOS app untouched and provides a backend-backed web MVP with Google sign-in, Classroom sync, SQLite persistence, subjects, timetable, attendance, submissions, and settings.

## Setup

```bash
cp .env.example .env.local
npm install
npm run db:setup
npm run dev
```

Open [http://localhost:3000](http://localhost:3000).

## Environment

Create a Google OAuth **Web application** client and enable the Google Classroom API.

```bash
GOOGLE_CLIENT_ID=your-web-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your-web-client-secret
AUTH_SECRET=replace-with-a-long-random-string
AUTH_URL=http://localhost:3000
DATABASE_URL="file:./dev.db"
```

Add this redirect URI to the Google OAuth client:

```text
http://localhost:3000/api/auth/callback/google
```

## Scripts

- `npm run dev` starts the local Next.js app.
- `npm run build` creates a production build.
- `npm run lint` runs ESLint.
- `npm run db:generate` regenerates Prisma Client.
- `npm run db:setup` creates `prisma/dev.db` from the committed SQLite migration if it does not exist.
- `npm run db:studio` opens Prisma Studio.

## Notes

The schema is defined in `prisma/schema.prisma`, with the initial SQL migration checked in under `prisma/migrations`. This first version uses SQLite for local development and is shaped so the models can move to Postgres later.
