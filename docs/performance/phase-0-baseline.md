# Phase 0 Performance Baseline

Date: 2026-07-12

## Status

Phase 0 is complete. The application builds, type-checks, lints, renders, authenticates through Google, reaches the active Supabase project, and deploys as a Vercel preview. Vercel Functions are pinned to Mumbai (`bom1`) to colocate compute with the Supabase `ap-south-1` database region.

## Build baseline

- Next.js: 15.5.15
- Production compilation: 647 ms locally on the final run
- Shared first-load JavaScript: 102 kB
- Authenticated-route first-load JavaScript: 106 kB
- Middleware bundle: 34.1 kB
- Lint: passed
- TypeScript: passed
- Prisma schema validation: passed

## Local anonymous baseline

Five warm requests to `/`:

- TTFB: 4.7-5.4 ms
- Total response time: 6.5-7.6 ms
- Compressed response: 14,968 bytes

Unauthenticated `/dashboard` middleware redirect:

- Status: 307
- TTFB: 21.5 ms

Authenticated dashboard reloads from the local machine completed in 1,281-1,466 ms. This includes repeated network round trips from the local machine to the Mumbai database and does not represent colocated Vercel latency.

## Rendered QA

- Desktop and 390 x 844 mobile landing layouts rendered meaningful content.
- No Next.js error overlay was present.
- Browser console contained no relevant warnings or errors.
- The `See how it helps` interaction navigated to `#how-it-helps`.
- The canonical `http://localhost:3000` Google OAuth flow completed successfully and landed on `/dashboard`.
- The authenticated dashboard rendered correctly after three reloads.
- The only browser-console error came from the browser-control extension, not UniBuddy.

## Database readiness

- Local development and Vercel now use the active UniBuddy Supabase project in `ap-south-1`.
- `DATABASE_URL` uses the transaction pooler on port 6543 with a one-connection Prisma limit.
- `DIRECT_URL` uses the native direct endpoint on port 5432 for Prisma migrations.
- The existing initial schema was baselined into Prisma's migration ledger without recreating tables.
- Migration `20260711120000_add_navigation_query_indexes` was applied successfully.
- `prisma migrate status` reports the database schema is up to date.
- Final database state during the baseline: one user, two sessions, and 54 assignments; the remaining application tables were empty.

## Deployment baseline

- Preview deployment: `https://web-fqhb3qih8-itej1310-6145s-projects.vercel.app`
- Deployment status: Ready
- Function region before configuration: Washington, D.C. (`iad1`)
- Function region after configuration: Mumbai (`bom1`)
- Development, Preview, and Production each contain all five required application environment variables.
- A new Auth.js secret was generated.
- UniBuddy now uses the OAuth client from its actual Google Cloud project.
- A replacement Google OAuth client secret was created and verified; the older secret was disabled and deleted.
- Localhost, the production aliases, and the stable Vercel preview alias are authorized OAuth origins and callback URLs.
- Production deployment: `https://uni-buddy-9cr7rifa2-itej1310-6145s-projects.vercel.app`
- Production status: Ready; the `uni-buddy-kappa.vercel.app` production alias now points to this release.
- Production functions run in Mumbai (`bom1`).

## Working-tree safety

Existing user source changes were preserved. No files were staged, committed, or reset. The Phase 0 source/configuration additions are the Vercel regional configuration and this baseline report; ignored local environment files were repaired in place.
