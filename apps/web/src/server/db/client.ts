import { drizzle } from "drizzle-orm/postgres-js";
import postgres from "postgres";
import * as schema from "./schema";

const globalForDb = globalThis as unknown as {
  sql?: ReturnType<typeof postgres>;
  url?: string;
};

export function getDb(databaseUrl = process.env.DATABASE_URL) {
  if (!databaseUrl) throw new Error("DATABASE_URL is required");
  if (!globalForDb.sql || globalForDb.url !== databaseUrl) {
    void globalForDb.sql?.end({ timeout: 1 });
    globalForDb.url = databaseUrl;
    globalForDb.sql = postgres(databaseUrl, {
      max: 10,
      idle_timeout: 20,
      connect_timeout: 10,
    });
  }
  return drizzle(globalForDb.sql, { schema });
}

export type Database = ReturnType<typeof getDb>;
