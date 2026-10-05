import { createHash } from "node:crypto";
import { readdirSync, readFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import {
  assertAcyclic,
  canonicalJson,
  contentPackManifestSchema,
  skillFileSchema,
  worldSchema,
  type Lesson,
  type SkillNode,
  type World,
} from "@axiom/content-schema";

const packDir = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../../../../content/packs/v1");

export function packDirectory() {
  return packDir;
}

export function loadV1Files() {
  const worlds = worldSchema.array().parse(JSON.parse(readFileSync(path.join(packDir, "worlds.json"), "utf8"))) as World[];
  const names = readdirSync(packDir)
    .filter((name) => name.endsWith(".json") && name !== "worlds.json")
    .sort();
  const files = names.map((name) =>
    skillFileSchema.parse(JSON.parse(readFileSync(path.join(packDir, name), "utf8"))),
  );
  files.sort((a, b) => a.skill.sortOrder - b.skill.sortOrder);
  return { worlds, files };
}

const lessonCounts: Record<string, number> = {
  "coordinate-plane": 2,
  quadrants: 1,
  "axis-distance": 1,
  "closer-point": 2,
  "arrow-parts": 2,
  "equal-arrows": 1,
  "add-arrows": 2,
  "scale-arrow": 2,
  "arrow-length": 1,
  "pip-checkpoint": 1,
  "vector-pair": 3,
  "component-add": 3,
  "scalar-multiply": 3,
  "length-unit": 3,
  "dot-agreement": 4,
  "pattern-match": 3,
  projection: 4,
  "matrix-numbers": 2,
  "matrix-vector": 4,
  "drawing-stretch": 3,
  "two-warps": 3,
  "eigen-direction": 3,
  "pip-capstone": 1,
};

const matrixSlugs = new Set(["matrix-numbers", "matrix-vector", "drawing-stretch", "two-warps", "eigen-direction"]);

function forbid(text: string, where: string, problems: string[]) {
  if (text.includes("!")) problems.push(`${where} contains an exclamation mark`);
  if (/incorrect/i.test(text)) problems.push(`${where} says Incorrect`);
}

export function validateLoadedPack(loaded = loadV1Files()) {
  const problems: string[] = [];
  const skills = loaded.files.map((file) => file.skill);
  const lessons = loaded.files.flatMap((file) => file.lessons);
  const skillIds = new Set<string>();
  const slugs = new Set<string>();
  const lessonIds = new Set<string>();

  if (skills.length !== Object.keys(lessonCounts).length) {
    problems.push(`Expected ${Object.keys(lessonCounts).length} skills, found ${skills.length}`);
  }

  for (const skill of skills) {
    if (skillIds.has(skill.id)) problems.push(`Duplicate skill id ${skill.id}`);
    skillIds.add(skill.id);
    if (slugs.has(skill.slug)) problems.push(`Duplicate slug ${skill.slug}`);
    slugs.add(skill.slug);
    forbid(skill.promise, `${skill.slug} promise`, problems);
    forbid(skill.pipAbility, `${skill.slug} ability`, problems);
    const expected = lessonCounts[skill.slug];
    const ownLessons = lessons.filter((lesson) => lesson.skillNodeId === skill.id);
    if (expected === undefined) problems.push(`Unexpected skill ${skill.slug}`);
    else if (ownLessons.length < expected) problems.push(`${skill.slug} has ${ownLessons.length} lessons, need ${expected}`);
  }

  for (const lesson of lessons) {
    if (lessonIds.has(lesson.id)) problems.push(`Duplicate lesson id ${lesson.id}`);
    lessonIds.add(lesson.id);
    if (!skillIds.has(lesson.skillNodeId)) problems.push(`Lesson ${lesson.id} points at a missing skill`);
    forbid(lesson.whyItMatters, `${lesson.title} why`, problems);
    const screenIds = new Set<string>();
    for (const screen of lesson.screens) {
      if (screenIds.has(screen.id)) problems.push(`${lesson.title} repeats screen ${screen.id}`);
      screenIds.add(screen.id);
      forbid(screen.prompt, `${lesson.title}/${screen.id} prompt`, problems);
      forbid(screen.correctMessage, `${lesson.title}/${screen.id} correct`, problems);
      for (const [code, message] of Object.entries(screen.feedback)) {
        forbid(message, `${lesson.title}/${screen.id}/${code}`, problems);
      }
    }
  }

  const bySlug = new Map(skills.map((skill) => [skill.slug, skill]));
  const spaceOrder = [
    "coordinate-plane",
    "quadrants",
    "axis-distance",
    "closer-point",
    "arrow-parts",
    "equal-arrows",
    "add-arrows",
    "scale-arrow",
    "arrow-length",
    "pip-checkpoint",
  ];
  const vectorOrder = [
    "vector-pair",
    "component-add",
    "scalar-multiply",
    "length-unit",
    "dot-agreement",
    "pattern-match",
    "projection",
    "matrix-numbers",
    "matrix-vector",
    "drawing-stretch",
    "two-warps",
    "eigen-direction",
    "pip-capstone",
  ];

  const chain = (order: string[], firstExtra: string[] | null) => {
    order.forEach((slug, index) => {
      const skill = bySlug.get(slug);
      if (!skill) return;
      const expected = index === 0 ? (firstExtra ?? []) : [bySlug.get(order[index - 1]!)!.id];
      const actual = [...skill.prereqIds].sort();
      const want = [...expected].sort();
      if (actual.join() !== want.join()) {
        problems.push(`${slug} prerequisites are ${actual.join(", ") || "empty"}`);
      }
    });
  };
  chain(spaceOrder, []);
  chain(vectorOrder, [bySlug.get("pip-checkpoint")?.id].filter((id): id is string => Boolean(id)));

  const spaceIds = new Set(spaceOrder.map((slug) => bySlug.get(slug)?.id));
  const dragCount = lessons
    .filter((lesson) => spaceIds.has(lesson.skillNodeId))
    .flatMap((lesson) => lesson.screens)
    .filter((screen) => screen.primitive.type === "dragArrow").length;
  if (dragCount < 4) problems.push(`Space world has ${dragCount} drag arrows, need 4`);

  for (const slug of matrixSlugs) {
    const skill = bySlug.get(slug);
    const usesMatrix = lessons
      .filter((lesson) => lesson.skillNodeId === skill?.id)
      .some((lesson) => lesson.screens.some((screen) => screen.primitive.type === "matrixWarp"));
    if (!usesMatrix) problems.push(`${slug} never uses matrixWarp`);
  }

  const vectorIds = new Set(vectorOrder.map((slug) => bySlug.get(slug)?.id));
  const matchCount = lessons
    .filter((lesson) => vectorIds.has(lesson.skillNodeId))
    .flatMap((lesson) => lesson.screens)
    .filter((screen) => screen.primitive.type === "match").length;
  if (matchCount < 2) problems.push(`Vectors world has ${matchCount} match screens, need 2`);

  const dot = lessons.filter((lesson) => lesson.skillNodeId === bySlug.get("dot-agreement")?.id);
  const firstDot = dot[0];
  if (firstDot) {
    const ids = new Set(firstDot.screens.map((screen) => screen.id));
    for (const id of ["same", "opposite", "perp"]) {
      if (!ids.has(id)) problems.push(`First dot-agreement lesson is missing ${id}`);
    }
    const same = firstDot.screens.find((screen) => screen.id === "same");
    if (same?.primitive.type === "dragArrow" && same.primitive.guideTip && same.primitive.guideStart) {
      const guideDx = same.primitive.guideTip.x - same.primitive.guideStart.x;
      const guideDy = same.primitive.guideTip.y - same.primitive.guideStart.y;
      const dx = same.primitive.targetTip.x - same.primitive.start.x;
      const dy = same.primitive.targetTip.y - same.primitive.start.y;
      const dotScore = guideDx * dx + guideDy * dy;
      if (dotScore <= 0) problems.push("The same-direction screen does not point with the guide arrow");
    } else {
      problems.push("The same-direction screen needs a visible guide arrow");
    }
  }

  const capstone = lessons.filter((lesson) => lesson.skillNodeId === bySlug.get("pip-capstone")?.id);
  if (capstone.length !== 1 || capstone[0]?.screens.length !== 8 || !capstone[0]?.capstone) {
    problems.push("pip-capstone needs one 8-screen lesson marked capstone");
  }

  try {
    assertAcyclic(skills.map((skill) => ({ id: skill.id, prereqIds: skill.prereqIds, sortOrder: skill.sortOrder })));
  } catch (error) {
    const nodeIds = error instanceof Error && "nodeIds" in error ? (error as { nodeIds: string[] }).nodeIds : [];
    problems.push(`Cycle: ${nodeIds.join(" -> ")}`);
  }

  if (problems.length > 0) {
    throw new Error(problems.join("\n"));
  }

  return { worlds: loaded.worlds, skills, lessons };
}

export function buildPackBody() {
  const { worlds, skills, lessons } = validateLoadedPack();
  const body = { version: "v1", skills, lessons };
  const sha256 = createHash("sha256").update(canonicalJson(body)).digest("hex");
  const manifest = contentPackManifestSchema.parse({
    version: "v1",
    sha256,
    publishedAt: "2026-10-05T12:00:00.000Z",
    skillIds: skills.map((skill) => skill.id),
    lessonIds: lessons.map((lesson) => lesson.id),
  });
  return { worlds, skills, lessons, body, sha256, manifest };
}

export type PackBody = {
  worlds: World[];
  skills: SkillNode[];
  lessons: Lesson[];
  body: { version: string; skills: SkillNode[]; lessons: Lesson[] };
  sha256: string;
  manifest: ReturnType<typeof contentPackManifestSchema.parse>;
};
