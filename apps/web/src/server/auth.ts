import { betterAuth } from "better-auth";
import { drizzleAdapter } from "better-auth/adapters/drizzle";
import { bearer } from "better-auth/plugins";
import { nextCookies } from "better-auth/next-js";
import { getDb } from "./db/client";
import { account, profiles, session, streaks, user, verification } from "./db/schema";

/** Loopback hosts the phone and browser use for the same local API port. */
function localTrustedOrigins(): string[] {
  const configured = process.env.BETTER_AUTH_URL ?? "http://localhost:3000";
  const url = new URL(configured);
  const port = url.port ? `:${url.port}` : "";
  const hosts = ["localhost", "127.0.0.1", "10.0.2.2"];
  return hosts.map((host) => `${url.protocol}//${host}${port}`);
}

export function createAuth() {
  const db = getDb();
  return betterAuth({
    secret: process.env.BETTER_AUTH_SECRET,
    baseURL: process.env.BETTER_AUTH_URL,
    basePath: "/api/v1/auth",
    trustedOrigins: localTrustedOrigins(),
    database: drizzleAdapter(db, {
      provider: "pg",
      schema: { user, session, account, verification },
    }),
    emailAndPassword: { enabled: true },
    user: {
      additionalFields: {
        role: {
          type: "string",
          defaultValue: "learner",
          input: false,
        },
      },
    },
    databaseHooks: {
      user: {
        create: {
          after: async (created) => {
            await db.insert(profiles).values({
              userId: created.id,
              displayName: created.name,
            });
            await db.insert(streaks).values({ userId: created.id });
          },
        },
      },
    },
    plugins: [bearer(), nextCookies()],
  });
}

let authSingleton: ReturnType<typeof createAuth> | undefined;

export function getAuth() {
  authSingleton ??= createAuth();
  return authSingleton;
}
