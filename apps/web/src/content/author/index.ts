import { skillFileSchema, type Lesson, type SkillNode } from "@axiom/content-schema";
import { spaceSkills } from "./space";
import { vectorSkills } from "./vectors";

export const SPACE_WORLD = "10000000-0000-4000-8000-000000000001";
export const VECTORS_WORLD = "10000000-0000-4000-8000-000000000002";

export const worlds = [
  { id: SPACE_WORLD, slug: "space", title: "Space", sortOrder: 0 },
  { id: VECTORS_WORLD, slug: "vectors", title: "Vectors and matrices", sortOrder: 1 },
];

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
  const drafts = [...spaceSkills, ...vectorSkills];
  let lessonCounter = 0;
  return drafts.map((draft, index) => {
    const id = skillUuid(index + 1);
    const previous = index === 0 ? null : drafts[index - 1];
    const prereqIds =
      draft.slug === "vector-pair"
        ? [skillUuid(drafts.findIndex((item) => item.slug === "pip-checkpoint") + 1)]
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
        worldId: draft.world === "space" ? SPACE_WORLD : VECTORS_WORLD,
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
