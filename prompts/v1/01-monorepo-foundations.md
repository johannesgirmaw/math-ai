# 01 — Monorepo foundations

You are scaffolding the Axiom monorepo. Prompt 00 is the working agreement. This prompt produces a bootable TypeScript workspace, a bootable Flutter app, local Postgres, lint, and CI. Do not add auth, lesson schema, or product screens beyond a hello surface.

## Goal

A new engineer can clone the repo, start Postgres, run the web hello page, and run the Flutter hello screen with the commands in the root README.

## Create this layout

```text
.
├── apps/
│   ├── web/                      Next.js App Router
│   └── mobile/                   Flutter
├── packages/
│   ├── content-schema/           private package @axiom/content-schema
│   └── algorithm-vectors/        private package @axiom/algorithm-vectors
├── content/packs/.gitkeep
├── design/.gitkeep
├── prompts/                      already present
├── docker-compose.yml
├── .env.example
├── package.json                  pnpm workspace root
├── pnpm-workspace.yaml
├── turbo.json
├── .gitignore
└── .github/workflows/ci.yml
```

## Tooling

- Package manager: pnpm. Workspace packages: `apps/web`, `packages/*`.
- Task runner: Turborepo. Pipeline tasks: `lint`, `typecheck`, `test`, `dev`.
- Node current LTS. TypeScript strict in every package.
- Next.js current stable with the App Router, `src/` directory, and `@/*` path alias.
- Tailwind CSS v4 in `apps/web`.
- shadcn/ui in `apps/web`, initialized with the official CLI for the current Next.js and Tailwind v4 setup. `components.json` uses the `@/` alias, RSC is enabled, and the icon library is `lucide-react`. Utilities live in `src/lib/utils.ts` (`cn` via `clsx` and `tailwind-merge`). Primitives live in `src/components/ui`. Install `button` in this prompt. Further primitives arrive in prompt 02. This is the only UI kit for Next.js.
- Flutter stable channel via `flutter create` with organization `app.axiom.mobile`, project name `axiom`, platforms iOS and Android. Remove the counter sample.
- Postgres 16 in Docker Compose. Database `axiom`. User, password, and port come from environment variables with safe local defaults documented in `.env.example`.
- ESLint and Prettier at the web workspace. `very_good_analysis` in the Flutter project.
- `@t3-oss/env-nextjs` parses server env. Missing `DATABASE_URL` fails the web build. The hello page may boot with a dummy local URL present in `.env.example`.

## Environment keys in `.env.example`

```text
DATABASE_URL=postgresql://axiom:axiom@localhost:5432/axiom
BETTER_AUTH_SECRET=
BETTER_AUTH_URL=http://localhost:3000
NEXT_PUBLIC_POSTHOG_KEY=
NEXT_PUBLIC_POSTHOG_HOST=
SENTRY_DSN=
RESEND_API_KEY=
```

Leave optional analytics keys blank. Do not call those services in this prompt.

## Root scripts

- `pnpm dev` starts the Next.js app.
- `pnpm lint`, `pnpm typecheck`, `pnpm test`.
- `pnpm db:up` and `pnpm db:down` wrap Docker Compose.
- Document `flutter pub get`, `flutter analyze`, and `flutter test` in the README. Flutter stays outside the pnpm workspace.

## Hello surfaces

- Web route `/` is a Server Component. It renders the word Axiom on background `#F6F1E7` and ink `#1C1915`, plus the shadcn `Button` from `@/components/ui/button` as a visual check that the kit is wired. The button has no action yet.
- Flutter `main.dart` shows the same word and colors inside a `MaterialApp`. No business logic.

`packages/content-schema` exports a placeholder `schemaVersion = 1` and a passing unit test. `packages/algorithm-vectors` exports an empty `fixtures` array and a passing test. Real schemas arrive in prompt 03.

## CI

GitHub Actions on pull request and push to the main branch:

1. Install pnpm and dependencies with a frozen lockfile once the lockfile exists.
2. Run typecheck and unit tests for the TypeScript workspace.
3. Set up Flutter stable and run `flutter analyze` and `flutter test` in `apps/mobile`.

Use pinned major versions of the actions that are current when you implement. Cache pnpm and the pub cache.

## Patterns

- Shared TypeScript is imported as `@axiom/content-schema` and `@axiom/algorithm-vectors`.
- Flutter does not import TypeScript. Cross-language truth is JSON fixtures checked into `packages/algorithm-vectors` later.
- `apps/web/src/server/db` may be an empty module comment pointing at prompt 04. Do not add Drizzle yet.

## Out of scope

Auth, Drizzle, Hono, lesson JSON, Riverpod features, and any screen past hello. shadcn is in scope for this prompt: the CLI install, `components.json`, `cn`, and `Button`. Do not theme the whole kit yet. Prompt 02 maps Axiom tokens onto it.

## Acceptance

- `pnpm dev` serves the hello page.
- `pnpm db:up` accepts a Postgres connection with the documented URL.
- `pnpm typecheck` and `pnpm test` pass.
- `flutter analyze` and `flutter test` pass.
- CI commands are written in the root README, including the three local commands above.
- `.env` is gitignored. `.env.example` is committed.
- `apps/web/components.json` exists, and `/` renders a shadcn `Button` imported from `@/components/ui/button`.
