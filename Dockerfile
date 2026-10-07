FROM node:22-bookworm-slim

RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates \
  && rm -rf /var/lib/apt/lists/* \
  && corepack enable \
  && corepack prepare pnpm@11.13.1 --activate

WORKDIR /app

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY apps/web/package.json apps/web/package.json
COPY packages/content-schema/package.json packages/content-schema/package.json
COPY packages/algorithm-vectors/package.json packages/algorithm-vectors/package.json

RUN pnpm install --frozen-lockfile

COPY . .

ENV NEXT_TELEMETRY_DISABLED=1
ENV SKIP_ENV_VALIDATION=true
ENV BETTER_AUTH_SECRET=build-time-secret-not-used-in-production-0123456789ab
ENV BETTER_AUTH_URL=https://math-si.felegemetsahft.com
ENV NEXT_PUBLIC_SITE_URL=https://math-si.felegemetsahft.com

RUN pnpm --filter @axiom/web build

COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh \
  && mkdir -p /app/apps/web/public/download

ENV NODE_ENV=production
ENV HOSTNAME=0.0.0.0
ENV PORT=3000
EXPOSE 3000

ENTRYPOINT ["/entrypoint.sh"]
