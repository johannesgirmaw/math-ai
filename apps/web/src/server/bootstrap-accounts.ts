import { eq } from "drizzle-orm";
import { getAuth } from "@/server/auth";
import { getDb } from "@/server/db/client";
import { user } from "@/server/db/schema";

const accounts = [
  {
    email: process.env.ADMIN_EMAIL,
    password: process.env.ADMIN_PASSWORD,
    name: "MATH SI Admin",
    role: "admin",
  },
  {
    email: process.env.LEARNER_EMAIL,
    password: process.env.LEARNER_PASSWORD,
    name: "MATH SI Learner",
    role: "learner",
  },
];

async function bootstrapAccounts() {
  const auth = getAuth();
  const db = getDb();

  for (const account of accounts) {
    if (!account.email || !account.password) {
      console.error("ADMIN_EMAIL, ADMIN_PASSWORD, LEARNER_EMAIL, and LEARNER_PASSWORD are required.");
      process.exit(1);
    }

    const existing = await db.select({ id: user.id }).from(user).where(eq(user.email, account.email));
    if (existing.length === 0) {
      await auth.api.signUpEmail({
        body: {
          email: account.email,
          password: account.password,
          name: account.name,
        },
      });
      console.log(`created ${account.role} ${account.email}`);
    } else {
      console.log(`exists ${account.role} ${account.email}`);
    }

    await db
      .update(user)
      .set({ role: account.role, emailVerified: true })
      .where(eq(user.email, account.email));
  }
}

bootstrapAccounts()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
