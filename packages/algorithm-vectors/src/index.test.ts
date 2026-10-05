import { readFileSync } from "node:fs";
import { describe, expect, it } from "vitest";
import { gradePrimitive } from "./grade";

type Fixture = {
  id: string;
  primitive: Parameters<typeof gradePrimitive>[0];
  answer: unknown;
  expect: { correct: boolean; errorCode: string | null };
};

const cases = JSON.parse(
  readFileSync(new URL("../fixtures/grading.json", import.meta.url), "utf8"),
) as { cases: Fixture[] };

describe("grading fixtures", () => {
  it.each(cases.cases)("$id matches the shared expected grade", (fixture) => {
    expect(gradePrimitive(fixture.primitive, fixture.answer)).toEqual(fixture.expect);
  });
});
