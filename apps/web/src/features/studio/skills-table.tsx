"use client";

import Link from "next/link";
import { useMemo } from "react";
import { parseAsString, useQueryState } from "nuqs";
import { createColumnHelper, flexRender, getCoreRowModel, useReactTable } from "@tanstack/react-table";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";

export type SkillRow = {
  id: string;
  title: string;
  promise: string;
  status: string;
  worldSlug: string;
};

const column = createColumnHelper<SkillRow>();

const columns = [
  column.accessor("title", {
    header: "Skill",
    cell: (info) => <Link href={`/admin/skills/${info.row.original.id}`}>{info.getValue()}</Link>,
  }),
  column.accessor("worldSlug", { header: "World" }),
  column.accessor("status", {
    header: "Status",
    cell: (info) => <Badge>{info.getValue()}</Badge>,
  }),
  column.accessor("promise", { header: "Promise" }),
];

export function SkillsTable({ rows }: { rows: SkillRow[] }) {
  const [world, setWorld] = useQueryState("world", parseAsString);
  const data = useMemo(() => (world ? rows.filter((row) => row.worldSlug === world) : rows), [rows, world]);
  const table = useReactTable({ data, columns, getCoreRowModel: getCoreRowModel() });
  const worlds = [...new Set(rows.map((row) => row.worldSlug))];

  return (
    <div className="flex flex-col gap-4">
      <div className="flex flex-wrap gap-2">
        <Button type="button" size="sm" variant={world ? "outline" : "default"} onClick={() => void setWorld(null)}>
          All worlds
        </Button>
        {worlds.map((slug) => (
          <Button
            key={slug}
            type="button"
            size="sm"
            variant={world === slug ? "default" : "outline"}
            onClick={() => void setWorld(slug)}
          >
            {slug}
          </Button>
        ))}
      </div>
      <Table>
        <TableHeader>
          {table.getHeaderGroups().map((group) => (
            <TableRow key={group.id}>
              {group.headers.map((header) => (
                <TableHead key={header.id}>{flexRender(header.column.columnDef.header, header.getContext())}</TableHead>
              ))}
            </TableRow>
          ))}
        </TableHeader>
        <TableBody>
          {table.getRowModel().rows.map((row) => (
            <TableRow key={row.id}>
              {row.getVisibleCells().map((cell) => (
                <TableCell key={cell.id}>{flexRender(cell.column.columnDef.cell, cell.getContext())}</TableCell>
              ))}
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  );
}
