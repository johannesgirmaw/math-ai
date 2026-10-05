"use client";

import { useState } from "react";
import { saveSkill } from "@/features/studio/actions";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

type OtherSkill = { id: string; title: string };

export function SkillForm({
  id,
  title,
  promise,
  pipAbility,
  sortOrder,
  prereqIds,
  others,
}: {
  id: string;
  title: string;
  promise: string;
  pipAbility: string;
  sortOrder: number;
  prereqIds: string[];
  others: OtherSkill[];
}) {
  const [selected, setSelected] = useState(prereqIds);
  return (
    <form action={saveSkill} className="flex flex-col gap-4">
      <input type="hidden" name="id" value={id} />
      <input type="hidden" name="prereqIds" value={selected.join(",")} />
      <Label htmlFor="title">Title</Label>
      <Input id="title" name="title" defaultValue={title} required />
      <Label htmlFor="promise">Promise</Label>
      <Input id="promise" name="promise" defaultValue={promise} required maxLength={80} />
      <Label htmlFor="pipAbility">Pip ability</Label>
      <Input id="pipAbility" name="pipAbility" defaultValue={pipAbility} required maxLength={80} />
      <Label htmlFor="sortOrder">Sort order</Label>
      <Input id="sortOrder" name="sortOrder" type="number" defaultValue={sortOrder} required />
      <p className="text-sm text-muted-foreground">Prerequisites</p>
      <div className="flex flex-wrap gap-2">
        {others.map((skill) => {
          const on = selected.includes(skill.id);
          return (
            <Button
              key={skill.id}
              type="button"
              variant={on ? "default" : "outline"}
              size="sm"
              onClick={() =>
                setSelected((current) => (on ? current.filter((item) => item !== skill.id) : [...current, skill.id]))
              }
            >
              {skill.title}
            </Button>
          );
        })}
      </div>
      <Button type="submit">Save</Button>
    </form>
  );
}
