import { describe, expect, it } from "vitest";
import { lessonSchema } from "./schemas";
import { CycleError, assertAcyclic, canonicalJson, topoRank, zigzag } from "./graph";

const a = "11111111-1111-4111-8111-111111111111";
const b = "22222222-2222-4222-8222-222222222222";
const c = "33333333-3333-4333-8333-333333333333";

describe("skill graph", () => {
  it("rejects a two-node cycle", () => {
    expect(() =>
      assertAcyclic([
        { id: a, prereqIds: [b], sortOrder: 0 },
        { id: b, prereqIds: [a], sortOrder: 1 },
      ]),
    ).toThrow(CycleError);
    try {
      assertAcyclic([
        { id: a, prereqIds: [b], sortOrder: 0 },
        { id: b, prereqIds: [a], sortOrder: 1 },
      ]);
    } catch (error) {
      expect(error).toBeInstanceOf(CycleError);
      expect((error as CycleError).nodeIds).toEqual(expect.arrayContaining([a, b]));
    }
  });

  it("ranks a chain 0, 1, 2", () => {
    const ranks = topoRank([
      { id: c, prereqIds: [b], sortOrder: 2 },
      { id: a, prereqIds: [], sortOrder: 0 },
      { id: b, prereqIds: [a], sortOrder: 1 },
    ]);
    expect(ranks.get(a)).toBe(0);
    expect(ranks.get(b)).toBe(1);
    expect(ranks.get(c)).toBe(2);
  });

  it("zigzags four nodes", () => {
    const lanes = zigzag([
      { id: a, prereqIds: [], sortOrder: 0 },
      { id: b, prereqIds: [], sortOrder: 1 },
      { id: c, prereqIds: [], sortOrder: 2 },
      { id: "44444444-4444-4444-8444-444444444444", prereqIds: [], sortOrder: 3 },
    ]);
    expect(lanes.map((lane) => lane.lane)).toEqual(["left", "right", "left", "right"]);
  });

  it("canonicalizes object key order", () => {
    expect(canonicalJson({ b: 1, a: { d: 2, c: 3 } })).toBe(canonicalJson({ a: { c: 3, d: 2 }, b: 1 }));
  });
});

describe("lesson schema", () => {
  const baseScreen = {
    id: "s1",
    prompt: "Which way does the arrow point?",
    primitive: {
      type: "choice" as const,
      options: [
        { id: "up", label: "Up" },
        { id: "right", label: "Right" },
      ],
      correctOptionId: "right",
    },
    feedback: { wrong_option: "The arrow points to the right." },
    easyWithinMs: 8000,
    correctMessage: "The tip sits to the right of the tail.",
  };

  it("rejects a choice screen missing wrong_option", () => {
    const lesson = {
      id: a,
      skillNodeId: b,
      title: "Arrow",
      version: 1,
      capstone: false,
      whyItMatters: "A layer reads this direction.",
      screens: Array.from({ length: 5 }, (_, index) => ({
        ...baseScreen,
        id: `s${index}`,
        feedback: {},
      })),
    };
    expect(lessonSchema.safeParse(lesson).success).toBe(false);
  });

  it("rejects a lesson with 4 screens", () => {
    const lesson = {
      id: a,
      skillNodeId: b,
      title: "Arrow",
      version: 1,
      capstone: false,
      whyItMatters: "A layer reads this direction.",
      screens: Array.from({ length: 4 }, (_, index) => ({ ...baseScreen, id: `s${index}` })),
    };
    expect(lessonSchema.safeParse(lesson).success).toBe(false);
  });
});
