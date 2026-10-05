import { asc, eq } from "drizzle-orm";
import { getDb } from "@/server/db/client";
import { skillNodes } from "@/server/db/schema";

export const seedPathTitles = [
  "Coordinate plane",
  "Quadrants",
  "Axis distance",
  "Closer point",
  "Arrow parts",
  "Equal arrows",
  "Add arrows",
  "Scale an arrow",
  "Arrow length",
  "Guide Pip",
  "Vector pair",
  "Component addition",
  "Scalar multiplication",
  "Length and direction",
  "Dot product",
  "Pattern match",
  "Projection",
  "Matrix numbers",
  "Matrix times vector",
  "Drawing stretch",
  "Two warps",
  "Eigen direction",
  "Teach Pip",
];

export async function getPublicPathTitles() {
  if (!process.env.DATABASE_URL) return seedPathTitles;
  try {
    const rows = await Promise.race([
      getDb()
        .select({ title: skillNodes.title })
        .from(skillNodes)
        .where(eq(skillNodes.status, "published"))
        .orderBy(asc(skillNodes.sortOrder)),
      new Promise<never>((_, reject) => {
        setTimeout(() => reject(new Error("path titles timed out")), 1500);
      }),
    ]);
    return rows.length > 0 ? rows.map((row) => row.title) : seedPathTitles;
  } catch {
    return seedPathTitles;
  }
}
