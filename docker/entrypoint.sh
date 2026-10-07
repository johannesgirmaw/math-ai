#!/bin/sh
set -eu
cd /app/apps/web
pnpm exec drizzle-kit migrate
pnpm exec tsx src/server/db/seed.ts
pnpm exec tsx src/server/bootstrap-accounts.ts
cd /app
exec pnpm --filter @axiom/web start
