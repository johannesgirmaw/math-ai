export class CycleError extends Error {
  readonly nodeIds: string[];

  constructor(nodeIds: string[]) {
    super(`Cycle detected: ${nodeIds.join(" -> ")}`);
    this.name = "CycleError";
    this.nodeIds = nodeIds;
  }
}

export type GraphNode = {
  id: string;
  prereqIds: string[];
  sortOrder: number;
};

function compareNodes(a: GraphNode, b: GraphNode) {
  if (a.sortOrder !== b.sortOrder) return a.sortOrder - b.sortOrder;
  return a.id.localeCompare(b.id);
}

export function assertAcyclic(nodes: GraphNode[]) {
  const color = new Map<string, "white" | "gray" | "black">();
  for (const node of nodes) color.set(node.id, "white");
  const byId = new Map(nodes.map((node) => [node.id, node]));
  const stack: string[] = [];

  const visit = (id: string) => {
    const current = color.get(id) ?? "white";
    if (current === "black") return;
    if (current === "gray") {
      const start = stack.indexOf(id);
      throw new CycleError([...stack.slice(start), id]);
    }
    color.set(id, "gray");
    stack.push(id);
    const node = byId.get(id);
    for (const prereqId of node?.prereqIds ?? []) {
      if (prereqId === id) {
        throw new CycleError([id, id]);
      }
      visit(prereqId);
    }
    stack.pop();
    color.set(id, "black");
  };

  for (const node of nodes) visit(node.id);
}

export function topoOrder<T extends GraphNode>(nodes: T[]): T[] {
  const byId = new Map(nodes.map((node) => [node.id, node]));
  const indegree = new Map(nodes.map((node) => [node.id, node.prereqIds.length]));
  const dependents = new Map<string, string[]>();
  for (const node of nodes) {
    for (const prereqId of node.prereqIds) {
      const list = dependents.get(prereqId) ?? [];
      list.push(node.id);
      dependents.set(prereqId, list);
    }
  }

  const ready = nodes.filter((node) => node.prereqIds.length === 0).sort(compareNodes);
  const ordered: T[] = [];

  while (ready.length > 0) {
    const next = ready.shift();
    if (!next) break;
    ordered.push(next);
    for (const dependentId of dependents.get(next.id) ?? []) {
      const remaining = (indegree.get(dependentId) ?? 1) - 1;
      indegree.set(dependentId, remaining);
      if (remaining === 0) {
        const dependent = byId.get(dependentId);
        if (dependent) {
          ready.push(dependent);
          ready.sort(compareNodes);
        }
      }
    }
  }

  if (ordered.length !== nodes.length) {
    throw new CycleError(nodes.map((node) => node.id));
  }
  return ordered;
}

export function topoRank(nodes: GraphNode[]) {
  const ordered = topoOrder(nodes);
  const ranks = new Map<string, number>();
  const byId = new Map(nodes.map((node) => [node.id, node]));
  for (const node of ordered) {
    if (node.prereqIds.length === 0) {
      ranks.set(node.id, 0);
      continue;
    }
    const parentRanks = node.prereqIds.map((id) => ranks.get(id) ?? ranks.get(byId.get(id)?.id ?? "") ?? 0);
    ranks.set(node.id, 1 + Math.max(...parentRanks));
  }
  return ranks;
}

export function zigzag(nodesInRank: GraphNode[]) {
  return [...nodesInRank].sort(compareNodes).map((node, index) => ({
    nodeId: node.id,
    lane: index % 2 === 0 ? ("left" as const) : ("right" as const),
  }));
}

function sortValue(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(sortValue);
  if (value && typeof value === "object") {
    const entries = Object.entries(value as Record<string, unknown>).sort(([a], [b]) => a.localeCompare(b));
    return Object.fromEntries(entries.map(([key, nested]) => [key, sortValue(nested)]));
  }
  return value;
}

export function canonicalJson(value: unknown) {
  return JSON.stringify(sortValue(value));
}
