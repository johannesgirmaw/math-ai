import { skillFileSchema, type Lesson, type SkillNode } from "@axiom/content-schema";
import { chanceSkills } from "./chance";
import { changeSkills } from "./calculus";
import { spaceSkills } from "./space";
import { vectorSkills } from "./vectors";

export const SPACE_WORLD = "10000000-0000-4000-8000-000000000001";
export const VECTORS_WORLD = "10000000-0000-4000-8000-000000000002";
export const CHANGE_WORLD = "10000000-0000-4000-8000-000000000003";
export const CHANCE_WORLD = "10000000-0000-4000-8000-000000000004";

export const worlds = [
  { id: SPACE_WORLD, slug: "space", title: "Space", sortOrder: 0 },
  { id: VECTORS_WORLD, slug: "vectors", title: "Vectors and matrices", sortOrder: 1 },
  { id: CHANGE_WORLD, slug: "change", title: "Change", sortOrder: 2 },
  { id: CHANCE_WORLD, slug: "chance", title: "Chance", sortOrder: 3 },
];

const worldIds = {
  space: SPACE_WORLD,
  vectors: VECTORS_WORLD,
  change: CHANGE_WORLD,
  chance: CHANCE_WORLD,
} as const;

function skillUuid(index: number) {
  return `20000000-0000-4000-8000-${index.toString(16).padStart(12, "0")}`;
}

function lessonUuid(index: number) {
  return `30000000-0000-4000-8000-${index.toString(16).padStart(12, "0")}`;
}

export type AuthoredSkillFile = {
  skill: SkillNode;
  lessons: Lesson[];
};

export function buildAuthoredFiles(): AuthoredSkillFile[] {
  const drafts = [...spaceSkills, ...vectorSkills, ...changeSkills, ...chanceSkills];
  let lessonCounter = 0;
  return drafts.map((draft, index) => {
    const id = skillUuid(index + 1);
    const previous = index === 0 ? null : drafts[index - 1];
    const prereqIds =
      draft.slug === "vector-pair"
        ? [skillUuid(drafts.findIndex((item) => item.slug === "pip-checkpoint") + 1)]
        : draft.slug === "rise-run"
          ? [skillUuid(drafts.findIndex((item) => item.slug === "pip-capstone") + 1)]
          : draft.slug === "outcomes"
            ? [skillUuid(drafts.findIndex((item) => item.slug === "downhill-step") + 1)]
            : previous && previous.world === draft.world
              ? [skillUuid(index)]
              : [];
    const lessons = draft.lessons.map((item) => {
      lessonCounter += 1;
      return {
        id: lessonUuid(lessonCounter),
        skillNodeId: id,
        title: item.title,
        version: 1,
        screens: item.screens,
        capstone: Boolean(item.capstone),
        whyItMatters: item.why,
      };
    });
    return skillFileSchema.parse({
      skill: {
        id,
        worldId: worldIds[draft.world],
        slug: draft.slug,
        title: draft.title,
        promise: draft.promise,
        prereqIds,
        sortOrder: index,
        pipAbility: draft.pipAbility,
        status: "published",
      },
      lessons,
    });
  });
}
