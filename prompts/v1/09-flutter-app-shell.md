# 09 — Flutter app shell

You are the Flutter engineer. Prompts 00 through 08 are done. Build the app skeleton, theme, routing, auth, and networking. Do not build the lesson player yet.

## Goal

A learner can create an account, sign in, and land on a home screen that shows their display name on the Axiom theme. The architecture is ready for features to plug in without new global singletons.

## Layout

```text
apps/mobile/lib/
  app/
    app.dart
    router.dart
    bootstrap.dart
  core/
    error/failure.dart
    network/api_client.dart
    storage/token_store.dart
    ui/                      from prompt 02
  features/
    auth/
      domain/learner.dart
      data/auth_dto.dart
      data/auth_repository.dart
      application/auth_providers.dart
      presentation/sign_in_page.dart
      presentation/sign_up_page.dart
    session/
      presentation/home_page.dart
```

`main.dart` calls `bootstrap()` which loads dotenv if you use `--dart-define=API_BASE_URL` instead of a dotenv file. Prefer `--dart-define=API_BASE_URL=http://10.0.2.2:3000` style configuration so secrets are not bundled. The base URL is required. Missing it shows a full-screen configuration error in debug and fails the build assert.

## Patterns

Clean architecture for the auth feature:

- `Learner` is a domain entity: `id`, `email`, `displayName`, `dailyGoalMinutes`, `role`.
- `AuthDto` maps JSON to `Learner` in the data layer. The presentation layer never reads JSON maps.
- `AuthRepository` is an abstract class. `HttpAuthRepository` implements it.
- Riverpod code generation provides the repository and the session controller. Run `build_runner`.
- `Result` operations return `Either<Failure, T>` from `fpdart`. `Failure` is a sealed type: `unauthorized`, `validation`, `network`, `unexpected`.
- Do not add Bloc, GetX, Provider, or a second Riverpod style of hand-written `ChangeNotifier`.

Routing with `go_router`:

- `/sign-in`, `/sign-up`, `/home`
- Redirect unauthenticated users to `/sign-in`
- Redirect authenticated users away from the auth pages to `/home`

Session state is an async notifier that reads the token, calls `GET /api/v1/me`, and emits the `Learner` or signed-out.

## Networking

One `Dio` instance:

- Base URL from dart-define
- Connect and receive timeouts 10 seconds
- Interceptor adds `Authorization: Bearer <token>` when the token store has a value
- On 401, delete the token and notify the session notifier to sign out
- Parse error bodies `{ error: { code, message } }` into `Failure`

`TokenStore` uses `flutter_secure_storage` only. Do not put the bearer token in shared preferences or Drift.

## Auth API

Implement sign-up and sign-in against the Better Auth bearer endpoints documented while executing prompt 05. After a successful sign-in, persist the token, then `GET /api/v1/me`.

Sign-up collects email, password, and display name. Password length at least 8. Show validation failures from the client before the request, and server `validation` failures under the form.

Sign-in collects email and password.

Home shows “Hello” plus `displayName` and a sign-out action that clears the token.

Apply `AppTheme.light()` at the `MaterialApp.router` root. Background paper, text ink.

## Tests

- Widget test: empty email on sign-in shows a validation message and does not call the repository. Inject a fake repository with a provider override.
- Repository test: a 401 response from a mocked Dio adapter maps to `Failure.unauthorized`.
- Mapper test: a `me` JSON fixture becomes a `Learner`.

`flutter analyze` stays clean under `very_good_analysis`.

## Out of scope

Path, lessons, placement, Drift, and analytics.

## Acceptance

- Fresh install shows sign-in.
- A test account created against a local API reaches home and shows the display name.
- Sign-out returns to sign-in and a following `GET /me` is not sent with the old token.
- The three tests pass.
