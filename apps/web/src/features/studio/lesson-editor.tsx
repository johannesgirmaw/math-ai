"use client";

import { useState } from "react";
import { canonicalJson, lessonSchema, type Lesson, type Screen } from "@axiom/content-schema";
import { saveLesson } from "@/features/studio/actions";
import { MathText } from "@/components/math-text";
import { ScreenPicture } from "@/features/studio/screen-picture";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";

function answerOf(screen: Screen) {
  const primitive = screen.primitive;
  switch (primitive.type) {
    case "choice":
      return primitive.options.find((option) => option.id === primitive.correctOptionId)?.label ?? primitive.correctOptionId;
    case "slider":
      return String(primitive.correctValue);
    case "dragArrow":
      return `(${primitive.targetTip.x}, ${primitive.targetTip.y})`;
    case "matrixWarp":
      return primitive.target.join(", ");
    case "match":
      return primitive.pairs.map((pair) => `${pair.leftId} → ${pair.rightId}`).join(", ");
    default:
      return "";
  }
}

function NumberField({
  label,
  value,
  onChange,
}: {
  label: string;
  value: number;
  onChange: (value: number) => void;
}) {
  return (
    <>
      <Label>{label}</Label>
      <Input type="number" value={value} onChange={(event) => onChange(Number(event.target.value))} />
    </>
  );
}

function PrimitiveFields({ screen, onChange }: { screen: Screen; onChange: (screen: Screen) => void }) {
  const primitive = screen.primitive;
  if (primitive.type === "choice") {
    return (
      <>
        {primitive.options.map((option, optionIndex) => (
          <div key={option.id} className="flex flex-col gap-2">
            <Label htmlFor={`${screen.id}-option-${option.id}`}>Option {option.id}</Label>
            <Input
              id={`${screen.id}-option-${option.id}`}
              value={option.label}
              onChange={(event) => {
                const options = primitive.options.map((item, index) =>
                  index === optionIndex ? { ...item, label: event.target.value } : item,
                );
                onChange({ ...screen, primitive: { ...primitive, options } });
              }}
            />
          </div>
        ))}
        <Label htmlFor={`${screen.id}-correct`}>Correct option</Label>
        <select
          id={`${screen.id}-correct`}
          className="h-14 rounded-[20px] border border-input bg-card px-4"
          value={primitive.correctOptionId}
          onChange={(event) => onChange({ ...screen, primitive: { ...primitive, correctOptionId: event.target.value } })}
        >
          {primitive.options.map((option) => (
            <option key={option.id} value={option.id}>
              {option.label}
            </option>
          ))}
        </select>
      </>
    );
  }
  if (primitive.type === "slider") {
    return (
      <>
        <NumberField label="Min" value={primitive.min} onChange={(min) => onChange({ ...screen, primitive: { ...primitive, min } })} />
        <NumberField label="Max" value={primitive.max} onChange={(max) => onChange({ ...screen, primitive: { ...primitive, max } })} />
        <NumberField label="Step" value={primitive.step} onChange={(step) => onChange({ ...screen, primitive: { ...primitive, step } })} />
        <NumberField
          label="Correct value"
          value={primitive.correctValue}
          onChange={(correctValue) => onChange({ ...screen, primitive: { ...primitive, correctValue } })}
        />
        <NumberField
          label="Tolerance"
          value={primitive.tolerance}
          onChange={(tolerance) => onChange({ ...screen, primitive: { ...primitive, tolerance } })}
        />
      </>
    );
  }
  if (primitive.type === "dragArrow") {
    return (
      <>
        <NumberField
          label="Tail x"
          value={primitive.start.x}
          onChange={(x) => onChange({ ...screen, primitive: { ...primitive, start: { ...primitive.start, x } } })}
        />
        <NumberField
          label="Tail y"
          value={primitive.start.y}
          onChange={(y) => onChange({ ...screen, primitive: { ...primitive, start: { ...primitive.start, y } } })}
        />
        <NumberField
          label="Tip x"
          value={primitive.targetTip.x}
          onChange={(x) => onChange({ ...screen, primitive: { ...primitive, targetTip: { ...primitive.targetTip, x } } })}
        />
        <NumberField
          label="Tip y"
          value={primitive.targetTip.y}
          onChange={(y) => onChange({ ...screen, primitive: { ...primitive, targetTip: { ...primitive.targetTip, y } } })}
        />
        <NumberField
          label="Tolerance"
          value={primitive.tolerance}
          onChange={(tolerance) => onChange({ ...screen, primitive: { ...primitive, tolerance } })}
        />
        <label className="flex items-center gap-2 text-sm">
          <input
            type="checkbox"
            checked={primitive.showTarget !== false}
            onChange={(event) =>
              onChange({ ...screen, primitive: { ...primitive, showTarget: event.target.checked } })
            }
          />
          Show the target mark
        </label>
      </>
    );
  }
  if (primitive.type === "matrixWarp") {
    return (
      <>
        {primitive.target.map((cell, index) => (
          <NumberField
            key={index}
            label={`Cell ${index + 1}`}
            value={cell}
            onChange={(next) => {
              const target = [...primitive.target] as [number, number, number, number];
              target[index] = next;
              onChange({ ...screen, primitive: { ...primitive, target } });
            }}
          />
        ))}
        <label className="flex items-center gap-2 text-sm">
          <input
            type="checkbox"
            checked={Boolean(primitive.showTarget)}
            onChange={(event) => onChange({ ...screen, primitive: { ...primitive, showTarget: event.target.checked } })}
          />
          Show the target numbers
        </label>
      </>
    );
  }
  return (
    <p className="text-sm text-muted-foreground">
      Pairs: {primitive.pairs.map((pair) => `${pair.leftId} → ${pair.rightId}`).join(", ")}. Edit labels in the JSON pane.
    </p>
  );
}

export function LessonEditor({ initial }: { initial: Lesson }) {
  const [lesson, setLesson] = useState(initial);
  const [jsonText, setJsonText] = useState(() => canonicalJson(initial));
  const [jsonError, setJsonError] = useState("");

  function commit(next: Lesson) {
    setLesson(next);
    setJsonText(canonicalJson(next));
    setJsonError("");
  }

  function patchScreen(index: number, screen: Screen) {
    commit({ ...lesson, screens: lesson.screens.map((item, itemIndex) => (itemIndex === index ? screen : item)) });
  }

  function onJson(text: string) {
    setJsonText(text);
    let body: unknown;
    try {
      body = JSON.parse(text);
    } catch {
      setJsonError("That JSON could not be read.");
      return;
    }
    const parsed = lessonSchema.safeParse(body);
    if (!parsed.success) {
      const issue = parsed.error.issues[0];
      setJsonError(`${issue?.path.join(".") || "lesson"}: ${issue?.message ?? "Invalid lesson"}`);
      return;
    }
    if (parsed.data.id !== lesson.id) {
      setJsonError("The lesson id must stay the same.");
      return;
    }
    setLesson(parsed.data);
    setJsonError("");
  }

  return (
    <div className="grid gap-6 lg:grid-cols-2">
      <form action={saveLesson} className="flex flex-col gap-4">
        <input type="hidden" name="id" value={lesson.id} />
        <input type="hidden" name="definition" value={canonicalJson(lesson)} />
        <Label htmlFor="title">Title</Label>
        <Input id="title" value={lesson.title} onChange={(event) => commit({ ...lesson, title: event.target.value })} />
        <Label htmlFor="why">Why it matters</Label>
        <Input
          id="why"
          value={lesson.whyItMatters}
          maxLength={140}
          onChange={(event) => commit({ ...lesson, whyItMatters: event.target.value })}
        />
        {lesson.screens.map((screen, index) => (
          <fieldset key={screen.id} className="flex flex-col gap-3 rounded-[20px] border border-border bg-card p-4">
            <legend className="px-2 text-sm text-muted-foreground">
              {screen.id} · {screen.primitive.type}
            </legend>
            <Label htmlFor={`${screen.id}-prompt`}>Prompt</Label>
            <Input
              id={`${screen.id}-prompt`}
              value={screen.prompt}
              maxLength={120}
              onChange={(event) => patchScreen(index, { ...screen, prompt: event.target.value })}
            />
            <Label htmlFor={`${screen.id}-ok`}>Correct message</Label>
            <Input
              id={`${screen.id}-ok`}
              value={screen.correctMessage}
              onChange={(event) => patchScreen(index, { ...screen, correctMessage: event.target.value })}
            />
            <Label htmlFor={`${screen.id}-easy`}>Easy within ms</Label>
            <Input
              id={`${screen.id}-easy`}
              type="number"
              value={screen.easyWithinMs}
              onChange={(event) => patchScreen(index, { ...screen, easyWithinMs: Number(event.target.value) })}
            />
            <PrimitiveFields screen={screen} onChange={(next) => patchScreen(index, next)} />
            {Object.entries(screen.feedback).map(([code, message]) => (
              <div key={code} className="flex flex-col gap-2">
                <Label htmlFor={`${screen.id}-${code}`}>{code}</Label>
                <Input
                  id={`${screen.id}-${code}`}
                  value={message}
                  onChange={(event) =>
                    patchScreen(index, { ...screen, feedback: { ...screen.feedback, [code]: event.target.value } })
                  }
                />
              </div>
            ))}
          </fieldset>
        ))}
        <div className="flex gap-3">
          <Button type="submit" name="intent" value="save" disabled={Boolean(jsonError)}>
            Save draft
          </Button>
          <Button type="submit" name="intent" value="review" variant="secondary" disabled={Boolean(jsonError)}>
            Submit for review
          </Button>
        </div>
      </form>
      <div className="flex flex-col gap-4">
        <section className="flex flex-col gap-3">
          {lesson.screens.map((screen) => (
            <article key={screen.id} className="rounded-[20px] border border-border bg-card p-4">
              <MathText text={screen.prompt} />
              <ScreenPicture screen={screen} />
              <p className="mt-2 text-sm text-muted-foreground">Answer: {answerOf(screen)}</p>
            </article>
          ))}
        </section>
        <Label htmlFor="json">Lesson JSON</Label>
        <Textarea id="json" rows={18} value={jsonText} onChange={(event) => onJson(event.target.value)} />
        {jsonError ? <p className="text-destructive">{jsonError}</p> : null}
      </div>
    </div>
  );
}
