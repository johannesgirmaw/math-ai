export type MasterySnapshot = {
  score: number;
  attempts: number;
  correctCount: number;
  recent: boolean[];
};

export type ItemFact = {
  skillId: string;
  correct: boolean;
};

export const emptyMastery = (): MasterySnapshot => ({
  score: 0,
  attempts: 0,
  correctCount: 0,
  recent: [],
});

export function applyMastery(snapshot: MasterySnapshot, fact: { correct: boolean }): MasterySnapshot {
  const result = fact.correct ? 1 : 0;
  const recent = [...snapshot.recent, fact.correct].slice(-2);
  return {
    score: snapshot.score + 0.35 * (result - snapshot.score),
    attempts: snapshot.attempts + 1,
    correctCount: snapshot.correctCount + result,
    recent,
  };
}

export function isMastered(snapshot: MasterySnapshot) {
  const lastTwoFail = snapshot.recent.length >= 2 && snapshot.recent[0] === false && snapshot.recent[1] === false;
  return snapshot.score >= 0.8 && snapshot.attempts >= 5 && !lastTwoFail;
}

export type Rating = "Again" | "Hard" | "Good" | "Easy";

export function rateAttempt(input: { correct: boolean; hadMiss: boolean; latencyMs: number; easyWithinMs: number }): Rating {
  if (!input.correct) return "Again";
  if (input.hadMiss) return "Hard";
  if (input.latencyMs <= input.easyWithinMs) return "Easy";
  return "Good";
}

export function nextPlacement(input: { low: number; high: number; correct: boolean }) {
  const mid = Math.floor((input.low + input.high) / 2);
  if (input.correct) return { low: mid + 1, high: input.high, mid };
  return { low: input.low, high: mid - 1, mid };
}

export function placementDone(input: { low: number; high: number; asked: number }) {
  return input.asked >= 6 || input.low >= input.high;
}

export function selectMission(input: { dueCount: number; lessonScreenCount: number; budget: number }) {
  const budget = Math.min(8, input.budget);
  const reviews = Math.min(2, input.dueCount, budget);
  const lessonScreens = Math.min(input.lessonScreenCount, budget - reviews);
  return { reviews, lessonScreens, budget };
}

export function missionBudget(dailyGoalMinutes: number) {
  if (dailyGoalMinutes >= 15) return 8;
  if (dailyGoalMinutes >= 10) return 6;
  return 5;
}
