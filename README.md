# Axiom

Daily practice for the math inside AI. Flutter is the learning app. Next.js serves the marketing site, the admin studio, and the mobile API.

## Local

```bash
cp .env.example .env
pnpm install
pnpm db:up
pnpm db:migrate
pnpm db:seed
pnpm dev
```

Phone app:

```bash
cd apps/mobile
flutter pub get
flutter analyze
flutter test
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:3000
```

On a physical phone, point `API_BASE_URL` at your computer's LAN address. The Android emulator can use `http://10.0.2.2:3000`. Start the API with `pnpm dev` first. Sign-in lands on a home screen with the learner's name.

Promote an author after they sign up:

```bash
pnpm --filter @axiom/web admin:promote --email=you@example.com --role=reviewer
```
