import { eq } from "drizzle-orm";
import { getDb } from "@/server/db/client";
import { user } from "@/server/db/schema";

async function promote() {
  const email = process.argv.find((arg) => arg.startsWith("--email="))?.slice("--email=".length);
  const role = process.argv.find((arg) => arg.startsWith("--role="))?.slice("--role=".length) ?? "author";

  if (!email) {
    console.error("Usage: pnpm admin:promote --email=you@example.com --role=author");
    process.exit(1);
  }

  const db = getDb();
  const updated = await db.update(user).set({ role }).where(eq(user.email, email)).returning({ id: user.id, role: user.role });
  if (updated.length === 0) {
    console.error("No user with that email.");
    process.exit(1);
  }
  console.log(updated[0]);
}

void promote();
