# Axiom implementation prompts

Axiom is a daily practice app for the math inside AI. The phone client is Flutter. One Next.js app serves the marketing site, the admin studio, and the versioned mobile API.

Execute `v1/` in numeric order. Finish a prompt’s acceptance checks before opening the next file. When two prompts disagree, the earlier prompt wins until a human revises it.

Product rules that every prompt inherits:

- Beachhead users are teens and adults who want the math inside AI to feel obvious.
- Version 1 ships the Space world and the Vectors and matrices world, plus a short placement.
- A mission is 5 to 8 screens and can be finished in a few minutes.
- One idea per screen. Prompt copy stays under about 120 characters.
- A wrong answer names the specific mistake.
- The learning path is free. Hearts and energy do not block practice.
- Grade on the device so feedback is instant and offline play works.
- Schedule spaced review on the server with FSRS. The phone stores facts and a cached queue.
- Send item results, never a client-invented mastery score.
- Each screen submission carries a client UUID. That id is the idempotency key.
- Pip, a small geometric robot, shows progress. Mastered skills open Pip’s abilities.

## Order

1. [00-how-to-implement.md](v1/00-how-to-implement.md)
2. [01-monorepo-foundations.md](v1/01-monorepo-foundations.md)
3. [02-design-system.md](v1/02-design-system.md)
4. [03-content-schema-and-skill-graph.md](v1/03-content-schema-and-skill-graph.md)
5. [04-postgres-and-domain-model.md](v1/04-postgres-and-domain-model.md)
6. [05-auth-and-mobile-api.md](v1/05-auth-and-mobile-api.md)
7. [06-learning-algorithms.md](v1/06-learning-algorithms.md)
8. [07-marketing-website.md](v1/07-marketing-website.md)
9. [08-admin-studio.md](v1/08-admin-studio.md)
10. [09-flutter-app-shell.md](v1/09-flutter-app-shell.md)
11. [10-flutter-lesson-player.md](v1/10-flutter-lesson-player.md)
12. [11-flutter-path-onboarding-habit.md](v1/11-flutter-path-onboarding-habit.md)
13. [12-offline-sync-and-content-packs.md](v1/12-offline-sync-and-content-packs.md)
14. [13-v1-lesson-content.md](v1/13-v1-lesson-content.md)
15. [14-testing-observability-and-acceptance.md](v1/14-testing-observability-and-acceptance.md)
