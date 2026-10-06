import { z } from "zod";

const id = z.string().uuid();

export const worldSchema = z.object({
  id,
  slug: z.string().regex(/^[a-z0-9]+(?:-[a-z0-9]+)*$/),
  title: z.string().min(1),
  sortOrder: z.number().int(),
});

export const skillNodeSchema = z.object({
  id,
  worldId: id,
  slug: z.string().regex(/^[a-z0-9]+(?:-[a-z0-9]+)*$/),
  title: z.string().min(1),
  promise: z.string().min(1).max(80),
  prereqIds: z.array(id),
  sortOrder: z.number().int(),
  pipAbility: z.string().min(1).max(80),
  status: z.enum(["draft", "published"]),
});

const optionSchema = z.object({
  id: z.string().min(1),
  label: z.string().min(1),
});

const pointSchema = z.object({ x: z.number(), y: z.number() });

const sceneArrowSchema = z.object({
  start: pointSchema,
  tip: pointSchema,
  guide: z.boolean().optional(),
});

export const choicePrimitiveSchema = z.object({
  type: z.literal("choice"),
  options: z.array(optionSchema).min(2).max(4),
  correctOptionId: z.string().min(1),
  arrows: z.array(sceneArrowSchema).max(3).optional(),
  score: z.enum(["positive", "zero", "negative"]).optional(),
});

export const sliderPrimitiveSchema = z.object({
  type: z.literal("slider"),
  min: z.number(),
  max: z.number(),
  step: z.number().positive(),
  correctValue: z.number(),
  tolerance: z.number().nonnegative(),
});

export const dragArrowPrimitiveSchema = z.object({
  type: z.literal("dragArrow"),
  planeWidth: z.number().positive(),
  planeHeight: z.number().positive(),
  start: pointSchema,
  targetTip: pointSchema,
  tolerance: z.number().positive(),
  guideStart: pointSchema.optional(),
  guideTip: pointSchema.optional(),
  score: z.enum(["positive", "zero", "negative"]).optional(),
});

export const matrixWarpPrimitiveSchema = z.object({
  type: z.literal("matrixWarp"),
  target: z.tuple([z.number(), z.number(), z.number(), z.number()]),
  initial: z.tuple([z.number(), z.number(), z.number(), z.number()]),
  tolerance: z.number().positive(),
  showTarget: z.boolean().optional(),
});

export const matchPrimitiveSchema = z.object({
  type: z.literal("match"),
  left: z.array(optionSchema).min(2),
  right: z.array(optionSchema).min(2),
  pairs: z.array(z.object({ leftId: z.string(), rightId: z.string() })).min(1),
});

export const primitiveSchema = z.discriminatedUnion("type", [
  choicePrimitiveSchema,
  sliderPrimitiveSchema,
  dragArrowPrimitiveSchema,
  matrixWarpPrimitiveSchema,
  matchPrimitiveSchema,
]);

const requiredErrors: Record<string, string[]> = {
  choice: ["wrong_option"],
  slider: ["too_low", "too_high"],
  dragArrow: ["wrong_direction", "wrong_length"],
  matrixWarp: ["wrong_cell"],
  match: ["incomplete", "wrong_pair"],
};

export const screenSchema = z
  .object({
    id: z.string().min(1),
    prompt: z.string().min(1).max(120),
    primitive: primitiveSchema,
    feedback: z.record(z.string().min(1).max(160)),
    easyWithinMs: z.number().int().positive(),
    correctMessage: z.string().min(1).max(160),
  })
  .superRefine((screen, ctx) => {
    const required = requiredErrors[screen.primitive.type] ?? [];
    for (const code of required) {
      if (!screen.feedback[code]) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          message: `Missing feedback for ${code}`,
          path: ["feedback", code],
        });
      }
    }
    if (screen.primitive.type === "slider") {
      const { min, max, correctValue } = screen.primitive;
      if (min >= max) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          message: "min must be less than max",
          path: ["primitive", "min"],
        });
      }
      if (correctValue < min || correctValue > max) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          message: "correctValue is outside the range",
          path: ["primitive", "correctValue"],
        });
      }
    }
    if (screen.primitive.type === "choice") {
      const ids = screen.primitive.options.map((option) => option.id);
      if (!ids.includes(screen.primitive.correctOptionId)) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          message: "correctOptionId is not an option",
          path: ["primitive", "correctOptionId"],
        });
      }
    }
  });

export const lessonSchema = z.object({
  id,
  skillNodeId: id,
  title: z.string().min(1),
  version: z.number().int().positive(),
  screens: z.array(screenSchema).min(5).max(8),
  capstone: z.boolean(),
  whyItMatters: z.string().min(1).max(140),
});

export const contentPackManifestSchema = z.object({
  version: z.string().min(1),
  sha256: z.string().regex(/^[a-f0-9]{64}$/),
  publishedAt: z.string().datetime(),
  skillIds: z.array(id),
  lessonIds: z.array(id),
});

export const skillFileSchema = z.object({
  skill: skillNodeSchema,
  lessons: z.array(lessonSchema).min(1),
});

export type World = z.infer<typeof worldSchema>;
export type SkillNode = z.infer<typeof skillNodeSchema>;
export type Screen = z.infer<typeof screenSchema>;
export type Lesson = z.infer<typeof lessonSchema>;
export type Primitive = z.infer<typeof primitiveSchema>;
export type ContentPackManifest = z.infer<typeof contentPackManifestSchema>;
