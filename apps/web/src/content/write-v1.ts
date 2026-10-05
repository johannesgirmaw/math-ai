import { writeFile } from "node:fs/promises";
import path from "node:path";
import { buildAuthoredFiles, worlds } from "./author";
import { packDirectory } from "./load-pack";

async function main() {
  const dir = packDirectory();
  const files = buildAuthoredFiles();
  await writeFile(path.join(dir, "worlds.json"), `${JSON.stringify(worlds, null, 2)}\n`);
  for (const file of files) {
    await writeFile(path.join(dir, `${file.skill.slug}.json`), `${JSON.stringify(file, null, 2)}\n`);
  }
  console.log(`Wrote ${files.length} skill files`);
}

main().catch((error) => {
  console.error(error instanceof Error ? error.message : error);
  process.exit(1);
});
