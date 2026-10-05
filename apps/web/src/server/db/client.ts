import { drizzle } from "drizzle-orm/postgres-js";
import postgres from "postgres";
import * as schema from "./schema";

const globalForDb = globalThis as unknown as { sql?: ReturnType<typeof postgres> };

export function getDb(databaseUrl = process.env.DATABASE_URL) {
  if (!databaseUrl) throw new Error("DATABASE_URL is required");
  const sql = globalForDb.sql ?? postgres(databaseUrl, { max: 10 });
  if (process.env.NODE_ENV !== "production") globalForDb.sql = sql;
  return drizzle(sql, { schema });
}

export type Database = ReturnType<typeof getDb>;
