import { randomUUID } from "node:crypto";
import { CycleError } from "@axiom/content-schema";
import { buildPackBody } from "./load-pack";
import { getDb } from "@/server/db/client";
import { auditLog, contentPacks, lessons } from "@/server/db/schema";
import { eq } from "drizzle-orm";

async function publish() {
  let pack: ReturnType<typeof buildPackBody>;
  try {
    pack = buildPackBody();
  } catch (error) {
    if (error instanceof CycleError) {
      console.error(`Cycle: ${error.nodeIds.join(" -> ")}`);
      process.exit(1);
    }
    console.error(error instanceof Error ? error.message : error);
    process.exit(1);
  }

  if (!process.env.DATABASE_URL) {
    console.error("DATABASE_URL is required to publish.");
    process.exit(1);
  }

  const version = `v${Date.now()}`;
  const packId = randomUUID();
  const db = getDb();
  await db.transaction(async (tx) => {
    await tx.insert(contentPacks).values({
      id: packId,
      version,
      sha256: pack.sha256,
      manifest: { ...pack.manifest, version },
      body: { ...pack.body, version },
    });
    for (const lesson of pack.lessons) {
      await tx.update(lessons).set({ status: "published" }).where(eq(lessons.id, lesson.id));
    }
    await tx.insert(auditLog).values({
      actorId: "content-publish",
      action: "publish_pack",
      entity: "content_pack",
      entityId: packId,
    });
  });
  console.log(JSON.stringify({ version, sha256: pack.sha256 }));
}

publish().catch((error) => {
  if (error instanceof CycleError) {
    console.error(`Cycle: ${error.nodeIds.join(" -> ")}`);
  } else {
    console.error(error);
  }
  process.exit(1);
});
