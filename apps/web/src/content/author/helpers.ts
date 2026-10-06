import type { Screen } from "@axiom/content-schema";

export function must(text: string, max: number, where: string) {
  if (text.length > max) throw new Error(`${where} is ${text.length} characters: ${text}`);
  if (text.includes("!")) throw new Error(`${where} contains an exclamation mark: ${text}`);
  if (/incorrect/i.test(text)) throw new Error(`${where} uses Incorrect: ${text}`);
  return text;
}

export function choice(
  id: string,
  prompt: string,
  options: [string, string][],
  correctOptionId: string,
  wrong: string,
  correctMessage: string,
  picture?: {
    arrows?: { start: [number, number]; tip: [number, number]; guide?: boolean }[];
    score?: "positive" | "zero" | "negative";
  },
): Screen {
  return {
    id,
    prompt: must(prompt, 120, `${id} prompt`),
    primitive: {
      type: "choice",
      options: options.map(([optionId, label]) => ({ id: optionId, label })),
      correctOptionId,
      ...(picture?.arrows
        ? {
            arrows: picture.arrows.map((arrow) => ({
              start: { x: arrow.start[0], y: arrow.start[1] },
              tip: { x: arrow.tip[0], y: arrow.tip[1] },
              ...(arrow.guide ? { guide: true } : {}),
            })),
          }
        : {}),
      ...(picture?.score ? { score: picture.score } : {}),
    },
    feedback: { wrong_option: must(wrong, 160, `${id} feedback`) },
    easyWithinMs: 8000,
    correctMessage: must(correctMessage, 160, `${id} correct`),
  };
}

export function slider(
  id: string,
  prompt: string,
  min: number,
  max: number,
  correctValue: number,
  tooLow: string,
  tooHigh: string,
  correctMessage: string,
  step = 1,
): Screen {
  return {
    id,
    prompt: must(prompt, 120, `${id} prompt`),
    primitive: { type: "slider", min, max, step, correctValue, tolerance: 0 },
    feedback: {
      too_low: must(tooLow, 160, `${id} low`),
      too_high: must(tooHigh, 160, `${id} high`),
    },
    easyWithinMs: 10000,
    correctMessage: must(correctMessage, 160, `${id} correct`),
  };
}

export function drag(
  id: string,
  prompt: string,
  start: [number, number],
  tip: [number, number],
  wrongDirection: string,
  wrongLength: string,
  correctMessage: string,
  guide?: { start: [number, number]; tip: [number, number] },
  score?: "positive" | "zero" | "negative",
  showTarget = true,
): Screen {
  const [sx, sy] = start;
  const [tx, ty] = tip;
  return {
    id,
    prompt: must(prompt, 120, `${id} prompt`),
    primitive: {
      type: "dragArrow",
      planeWidth: 10,
      planeHeight: 10,
      start: { x: sx, y: sy },
      targetTip: { x: tx, y: ty },
      tolerance: 0.8,
      ...(guide
        ? {
            guideStart: { x: guide.start[0], y: guide.start[1] },
            guideTip: { x: guide.tip[0], y: guide.tip[1] },
          }
        : {}),
      ...(score ? { score } : {}),
      ...(showTarget ? {} : { showTarget: false }),
    },
    feedback: {
      wrong_direction: must(wrongDirection, 160, `${id} direction`),
      wrong_length: must(wrongLength, 160, `${id} length`),
    },
    easyWithinMs: 12000,
    correctMessage: must(correctMessage, 160, `${id} correct`),
  };
}

export function matrix(
  id: string,
  prompt: string,
  target: [number, number, number, number],
  wrongCell: string,
  correctMessage: string,
  showTarget = false,
): Screen {
  return {
    id,
    prompt: must(prompt, 120, `${id} prompt`),
    primitive: {
      type: "matrixWarp",
      target,
      initial: [0, 0, 0, 0],
      tolerance: 0.1,
      ...(showTarget ? { showTarget: true } : {}),
    },
    feedback: { wrong_cell: must(wrongCell, 160, `${id} cell`) },
    easyWithinMs: 12000,
    correctMessage: must(correctMessage, 160, `${id} correct`),
  };
}

export function match(
  id: string,
  prompt: string,
  left: [string, string][],
  right: [string, string][],
  pairs: [string, string][],
  incomplete: string,
  wrongPair: string,
  correctMessage: string,
): Screen {
  return {
    id,
    prompt: must(prompt, 120, `${id} prompt`),
    primitive: {
      type: "match",
      left: left.map(([optionId, label]) => ({ id: optionId, label })),
      right: right.map(([optionId, label]) => ({ id: optionId, label })),
      pairs: pairs.map(([leftId, rightId]) => ({ leftId, rightId })),
    },
    feedback: {
      incomplete: must(incomplete, 160, `${id} incomplete`),
      wrong_pair: must(wrongPair, 160, `${id} pair`),
    },
    easyWithinMs: 10000,
    correctMessage: must(correctMessage, 160, `${id} correct`),
  };
}

export function meter(
  id: string,
  prompt: string,
  start: [number, number],
  tip: [number, number],
  guide: { start: [number, number]; tip: [number, number] },
  band: "positive" | "zero" | "negative",
  wrongDirection: string,
  wrongLength: string,
  correctMessage: string,
): Screen {
  return {
    id,
    prompt: must(prompt, 120, `${id} prompt`),
    primitive: {
      type: "meter",
      start: { x: start[0], y: start[1] },
      targetTip: { x: tip[0], y: tip[1] },
      tolerance: 0.8,
      guideStart: { x: guide.start[0], y: guide.start[1] },
      guideTip: { x: guide.tip[0], y: guide.tip[1] },
      band,
    },
    feedback: {
      wrong_direction: must(wrongDirection, 160, `${id} direction`),
      wrong_length: must(wrongLength, 160, `${id} length`),
    },
    easyWithinMs: 12000,
    correctMessage: must(correctMessage, 160, `${id} correct`),
  };
}

export function sheet(
  id: string,
  prompt: string,
  target: [number, number, number, number],
  wrongCell: string,
  correctMessage: string,
  showGhost = false,
  initial: [number, number, number, number] = [1, 0, 0, 1],
): Screen {
  const resting = target.every((value, index) => value === initial[index])
    ? ([1.4, 0.2, 0, 0.8] as [number, number, number, number])
    : initial;
  return {
    id,
    prompt: must(prompt, 120, `${id} prompt`),
    primitive: {
      type: "sheet",
      target,
      initial: resting,
      tolerance: 0.35,
      ...(showGhost ? { showGhost: true } : {}),
    },
    feedback: { wrong_cell: must(wrongCell, 160, `${id} cell`) },
    easyWithinMs: 14000,
    correctMessage: must(correctMessage, 160, `${id} correct`),
  };
}

export function hill(
  id: string,
  prompt: string,
  start: [number, number],
  slope: number,
  run: number,
  rise: number,
  wrongDirection: string,
  wrongLength: string,
  correctMessage: string,
): Screen {
  return {
    id,
    prompt: must(prompt, 120, `${id} prompt`),
    primitive: {
      type: "hill",
      start: { x: start[0], y: start[1] },
      slope,
      correctRun: run,
      correctRise: rise,
      tolerance: 0.7,
    },
    feedback: {
      wrong_direction: must(wrongDirection, 160, `${id} direction`),
      wrong_length: must(wrongLength, 160, `${id} length`),
    },
    easyWithinMs: 12000,
    correctMessage: must(correctMessage, 160, `${id} correct`),
  };
}

export function bagPick(
  id: string,
  prompt: string,
  bags: [string, string[]][],
  face: string,
  correctBagId: string,
  wrong: string,
  correctMessage: string,
): Screen {
  return {
    id,
    prompt: must(prompt, 120, `${id} prompt`),
    primitive: {
      type: "bag",
      task: "pick",
      bags: bags.map(([bagId, chips]) => ({ id: bagId, chips })),
      face,
      correctBagId,
    },
    feedback: { wrong_bag: must(wrong, 160, `${id} bag`) },
    easyWithinMs: 10000,
    correctMessage: must(correctMessage, 160, `${id} correct`),
  };
}

export function bagCount(
  id: string,
  prompt: string,
  chips: string[],
  face: string,
  correctCount: number,
  tooLow: string,
  tooHigh: string,
  correctMessage: string,
): Screen {
  return {
    id,
    prompt: must(prompt, 120, `${id} prompt`),
    primitive: { type: "bag", task: "count", bags: [{ id: "bag", chips }], face, correctCount },
    feedback: {
      too_low: must(tooLow, 160, `${id} low`),
      too_high: must(tooHigh, 160, `${id} high`),
    },
    easyWithinMs: 10000,
    correctMessage: must(correctMessage, 160, `${id} correct`),
  };
}

export function bagSelect(
  id: string,
  prompt: string,
  options: [string, string][],
  correctIds: string[],
  incomplete: string,
  wrongChip: string,
  correctMessage: string,
): Screen {
  return {
    id,
    prompt: must(prompt, 120, `${id} prompt`),
    primitive: {
      type: "bag",
      task: "select",
      options: options.map(([optionId, label]) => ({ id: optionId, label })),
      correctIds,
    },
    feedback: {
      incomplete: must(incomplete, 160, `${id} incomplete`),
      wrong_chip: must(wrongChip, 160, `${id} chip`),
    },
    easyWithinMs: 12000,
    correctMessage: must(correctMessage, 160, `${id} correct`),
  };
}

export function beamBalance(
  id: string,
  prompt: string,
  blocks: number[],
  fulcrum: number,
  tooLow: string,
  tooHigh: string,
  correctMessage: string,
): Screen {
  return {
    id,
    prompt: must(prompt, 120, `${id} prompt`),
    primitive: { type: "beam", task: "balance", blocks, correctFulcrum: fulcrum, tolerance: 0.45 },
    feedback: {
      too_low: must(tooLow, 160, `${id} low`),
      too_high: must(tooHigh, 160, `${id} high`),
    },
    easyWithinMs: 12000,
    correctMessage: must(correctMessage, 160, `${id} correct`),
  };
}

export function beamPick(
  id: string,
  prompt: string,
  beams: [string, number[]][],
  correctId: string,
  wrong: string,
  correctMessage: string,
): Screen {
  return {
    id,
    prompt: must(prompt, 120, `${id} prompt`),
    primitive: {
      type: "beam",
      task: "pick",
      beams: beams.map(([beamId, blocks]) => ({ id: beamId, blocks })),
      correctId,
    },
    feedback: { wrong_beam: must(wrong, 160, `${id} beam`) },
    easyWithinMs: 10000,
    correctMessage: must(correctMessage, 160, `${id} correct`),
  };
}

export type LessonDraft = {
  title: string;
  why: string;
  screens: Screen[];
  capstone?: boolean;
};

export type SkillDraft = {
  slug: string;
  title: string;
  promise: string;
  pipAbility: string;
  world: "space" | "vectors" | "change" | "chance";
  lessons: LessonDraft[];
};

export function skill(
  slug: string,
  title: string,
  promise: string,
  pipAbility: string,
  world: "space" | "vectors" | "change" | "chance",
  lessons: LessonDraft[],
): SkillDraft {
  return {
    slug,
    title,
    promise: must(promise, 80, `${slug} promise`),
    pipAbility: must(pipAbility, 80, `${slug} ability`),
    world,
    lessons: lessons.map((lesson) => ({
      ...lesson,
      why: must(lesson.why, 140, `${slug} why`),
      title: must(lesson.title, 80, `${slug} title`),
    })),
  };
}

export function lesson(title: string, why: string, screens: Screen[], capstone = false): LessonDraft {
  const ids = new Set<string>();
  for (const screen of screens) {
    if (ids.has(screen.id)) throw new Error(`Duplicate screen ${screen.id} in ${title}`);
    ids.add(screen.id);
  }
  if (screens.length < 5 || screens.length > 8) {
    throw new Error(`${title} has ${screens.length} screens`);
  }
  return { title, why, screens, capstone };
}
