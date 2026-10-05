import { describe, expect, it } from "vitest";
import { buildPackBody } from "./load-pack";

describe("version 1 pack", () => {
  it("validates the authored lessons and hashes the body", () => {
    const pack = buildPackBody();
    expect(pack.skills).toHaveLength(23);
    expect(pack.lessons.length).toBeGreaterThanOrEqual(54);
    expect(pack.sha256).toMatch(/^[a-f0-9]{64}$/);
    const dot = pack.lessons.find((lesson) => lesson.title === "Same, opposite, right angle");
    expect(dot?.screens.map((screen) => screen.id)).toEqual(["same", "opposite", "perp", "score", "neuron"]);
  });
});