import { createEmptyCard, fsrs, Rating, type Card, type Grade } from "ts-fsrs";
import type { Rating as AxiomRating } from "./mastery";

const scheduler = fsrs();

const ratingMap: Record<AxiomRating, Grade> = {
  Again: Rating.Again,
  Hard: Rating.Hard,
  Good: Rating.Good,
  Easy: Rating.Easy,
};

export type ReviewCardState = {
  dueAt: string;
  stability: number;
  difficulty: number;
  reps: number;
  lapses: number;
  state: string;
  fsrs: Card;
};

export function emptyReviewCard(now: Date): ReviewCardState {
  const card = createEmptyCard(now);
  return {
    dueAt: card.due.toISOString(),
    stability: card.stability,
    difficulty: card.difficulty,
    reps: card.reps,
    lapses: card.lapses,
    state: String(card.state),
    fsrs: card,
  };
}

export function scheduleReview(card: Card | null, rating: AxiomRating, now: Date): ReviewCardState {
  const current: Card = card ?? createEmptyCard(now);
  const scheduled = scheduler.repeat(current, now)[ratingMap[rating]];
  const next = scheduled.card;
  return {
    dueAt: next.due.toISOString(),
    stability: next.stability,
    difficulty: next.difficulty,
    reps: next.reps,
    lapses: next.lapses,
    state: String(next.state),
    fsrs: next,
  };
}
