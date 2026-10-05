export type Grade = { correct: boolean; errorCode: string | null };

type Point = { x: number; y: number };
type Option = { id: string; label: string };
type Pair = { leftId: string; rightId: string };

type Primitive =
  | { type: "choice"; options: Option[]; correctOptionId: string }
  | { type: "slider"; min: number; max: number; step: number; correctValue: number; tolerance: number }
  | {
      type: "dragArrow";
      planeWidth: number;
      planeHeight: number;
      start: Point;
      targetTip: Point;
      tolerance: number;
    }
  | { type: "matrixWarp"; target: number[]; initial: number[]; tolerance: number }
  | { type: "match"; left: Option[]; right: Option[]; pairs: Pair[] };

function wrong(errorCode: string): Grade {
  return { correct: false, errorCode };
}

function ok(): Grade {
  return { correct: true, errorCode: null };
}

function angleDegrees(ax: number, ay: number, bx: number, by: number) {
  const aLen = Math.hypot(ax, ay);
  const bLen = Math.hypot(bx, by);
  if (aLen === 0 || bLen === 0) return 180;
  const cos = Math.min(1, Math.max(-1, (ax * bx + ay * by) / (aLen * bLen)));
  return (Math.acos(cos) * 180) / Math.PI;
}

function asPairs(answer: unknown): Pair[] {
  if (!Array.isArray(answer)) return [];
  return answer.filter((item): item is Pair => {
    if (typeof item !== "object" || item === null) return false;
    const pair = item as { leftId?: unknown; rightId?: unknown };
    return typeof pair.leftId === "string" && typeof pair.rightId === "string";
  });
}

export function gradePrimitive(primitive: Primitive, answer: unknown): Grade {
  switch (primitive.type) {
    case "choice":
      return answer === primitive.correctOptionId ? ok() : wrong("wrong_option");
    case "slider": {
      if (typeof answer !== "number") return wrong("too_low");
      if (answer < primitive.correctValue - primitive.tolerance) return wrong("too_low");
      if (answer > primitive.correctValue + primitive.tolerance) return wrong("too_high");
      return ok();
    }
    case "dragArrow": {
      const tip = answer as { x?: unknown; y?: unknown } | null;
      if (!tip || typeof tip.x !== "number" || typeof tip.y !== "number") return wrong("wrong_length");
      const dx = tip.x - primitive.start.x;
      const dy = tip.y - primitive.start.y;
      if (dx === 0 && dy === 0) return wrong("wrong_length");
      const tx = primitive.targetTip.x - primitive.start.x;
      const ty = primitive.targetTip.y - primitive.start.y;
      if (angleDegrees(tx, ty, dx, dy) > 25) return wrong("wrong_direction");
      const distance = Math.hypot(tip.x - primitive.targetTip.x, tip.y - primitive.targetTip.y);
      if (distance > primitive.tolerance) return wrong("wrong_length");
      return ok();
    }
    case "matrixWarp": {
      if (!Array.isArray(answer) || answer.length !== primitive.target.length) return wrong("wrong_cell");
      const bad = primitive.target.some((cell, index) => {
        const value = answer[index];
        return typeof value !== "number" || Math.abs(value - cell) > primitive.tolerance;
      });
      return bad ? wrong("wrong_cell") : ok();
    }
    case "match": {
      const pairs = asPairs(answer);
      if (pairs.length < primitive.pairs.length) return wrong("incomplete");
      const expected = new Set(primitive.pairs.map((pair) => `${pair.leftId}:${pair.rightId}`));
      const wrongPair = pairs.some((pair) => !expected.has(`${pair.leftId}:${pair.rightId}`));
      return wrongPair ? wrong("wrong_pair") : ok();
    }
    default:
      return wrong("wrong_option");
  }
}
