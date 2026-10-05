import { describe, expect, it } from "vitest";
import { applyMastery, emptyMastery, isMastered, nextPlacement, rateAttempt, selectMission } from "./mastery";
import { scheduleReview } from "./review";

describe("mastery", () => {
  it("crosses 0.8 after repeated correct answers", () => {
    let snapshot = emptyMastery();
    for (let i = 0; i < 8; i += 1) snapshot = applyMastery(snapshot, { correct: true });
    expect(snapshot.score).toBeGreaterThanOrEqual(0.8);
    expect(isMastered(snapshot)).toBe(true);
  });

  it("does not master two recent misses even with a high score", () => {
    const snapshot = { score: 0.95, attempts: 6, correctCount: 4, recent: [false, false] };
    expect(isMastered(snapshot)).toBe(false);
  });
});

describe("placement", () => {
  it("raises the floor on a correct answer", () => {
    expect(nextPlacement({ low: 0, high: 7, correct: true }).low).toBeGreaterThan(0);
  });
});

describe("rating", () => {
  it("maps outcomes", () => {
    expect(rateAttempt({ correct: false, hadMiss: false, latencyMs: 1000, easyWithinMs: 8000 })).toBe("Again");
    expect(rateAttempt({ correct: true, hadMiss: true, latencyMs: 1000, easyWithinMs: 8000 })).toBe("Hard");
    expect(rateAttempt({ correct: true, hadMiss: false, latencyMs: 1000, easyWithinMs: 8000 })).toBe("Easy");
    expect(rateAttempt({ correct: true, hadMiss: false, latencyMs: 9000, easyWithinMs: 8000 })).toBe("Good");
  });
});

describe("mission", () => {
  it("keeps two reviews inside an 8-screen budget", () => {
    expect(selectMission({ dueCount: 4, lessonScreenCount: 6, budget: 8 })).toEqual({
      reviews: 2,
      lessonScreens: 6,
      budget: 8,
    });
  });
});

describe("fsrs", () => {
  it("moves Good later than Again", () => {
    const now = new Date("2026-10-05T12:00:00.000Z");
    const again = scheduleReview(null, "Again", now);
    const good = scheduleReview(null, "Good", now);
    expect(new Date(good.dueAt).getTime()).toBeGreaterThan(now.getTime());
    expect(new Date(again.dueAt).getTime()).toBeLessThanOrEqual(new Date(good.dueAt).getTime());
  });
});
