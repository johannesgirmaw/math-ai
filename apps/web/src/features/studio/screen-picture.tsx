import type { Screen } from "@axiom/content-schema";

function point(x: number, y: number, width = 10, height = 10) {
  return { x: (x / width) * 100, y: 100 - (y / height) * 100 };
}

function Arrow({
  start,
  tip,
  color,
}: {
  start: { x: number; y: number };
  tip: { x: number; y: number };
  color: string;
}) {
  return (
    <line
      x1={start.x}
      y1={start.y}
      x2={tip.x}
      y2={tip.y}
      stroke={color}
      strokeWidth="2"
      strokeLinecap="round"
    />
  );
}

export function ScreenPicture({ screen }: { screen: Screen }) {
  const primitive = screen.primitive;
  if (primitive.type === "dragArrow") {
    const guide =
      primitive.guideStart && primitive.guideTip
        ? {
            start: point(primitive.guideStart.x, primitive.guideStart.y),
            tip: point(primitive.guideTip.x, primitive.guideTip.y),
          }
        : null;
    const tail = point(primitive.start.x, primitive.start.y);
    const head = point(primitive.targetTip.x, primitive.targetTip.y);
    return (
      <svg viewBox="0 0 100 100" className="mt-3 h-40 w-full rounded-[20px] bg-background" aria-hidden="true">
        {Array.from({ length: 11 }, (_, index) => (
          <g key={index} stroke="#E4DCCF" strokeWidth="0.4">
            <line x1={index * 10} y1="0" x2={index * 10} y2="100" />
            <line x1="0" y1={index * 10} x2="100" y2={index * 10} />
          </g>
        ))}
        {guide ? <Arrow start={guide.start} tip={guide.tip} color="#1C191559" /> : null}
        {primitive.showTarget === false ? null : (
          <circle cx={head.x} cy={head.y} r="3" fill="none" stroke="#E4DCCF" strokeWidth="1.5" />
        )}
        <Arrow start={tail} tip={head} color="#2454FF" />
        {primitive.score ? (
          <text x="92" y="12" textAnchor="end" fill={primitive.score === "negative" ? "#8C3A32" : "#1F7A4D"}>
            {primitive.score === "positive" ? "+" : primitive.score === "negative" ? "−" : "0"}
          </text>
        ) : null}
      </svg>
    );
  }
  if (primitive.type === "choice" && primitive.arrows && primitive.arrows.length > 0) {
    return (
      <svg viewBox="0 0 100 100" className="mt-3 h-40 w-full rounded-[20px] bg-background" aria-hidden="true">
        {primitive.arrows.map((arrow, index) => (
          <Arrow
            key={index}
            start={point(arrow.start.x, arrow.start.y)}
            tip={point(arrow.tip.x, arrow.tip.y)}
            color={arrow.guide ? "#1C191559" : "#2454FF"}
          />
        ))}
      </svg>
    );
  }
  if (primitive.type === "matrixWarp") {
    const map = (x: number, y: number, cells: number[]) => {
      const nx = (cells[0] ?? 0) * x + (cells[1] ?? 0) * y;
      const ny = (cells[2] ?? 0) * x + (cells[3] ?? 0) * y;
      return `${50 + nx * 16},${50 - ny * 16}`;
    };
    const square = (cells: number[]) =>
      [map(-1, -1, cells), map(1, -1, cells), map(1, 1, cells), map(-1, 1, cells)].join(" ");
    return (
      <svg viewBox="0 0 100 100" className="mt-3 h-40 w-full rounded-[20px] bg-background" aria-hidden="true">
        <polygon points={square([1, 0, 0, 1])} fill="none" stroke="#E4DCCF" strokeWidth="2" />
        <polygon points={square(primitive.target)} fill="none" stroke="#2454FF" strokeWidth="2" />
      </svg>
    );
  }
  if (primitive.type === "match") {
    const rightLabel = new Map(primitive.right.map((item) => [item.id, item.label]));
    return (
      <div className="mt-3 grid grid-cols-2 gap-3 text-sm">
        <div className="flex flex-col gap-2">
          {primitive.left.map((item) => {
            const pair = primitive.pairs.find((entry) => entry.leftId === item.id);
            return (
              <p key={item.id} className="rounded-[16px] border border-border px-3 py-2">
                {item.label}
                {pair ? ` → ${rightLabel.get(pair.rightId) ?? pair.rightId}` : ""}
              </p>
            );
          })}
        </div>
        <div className="flex flex-col gap-2">
          {primitive.right.map((item) => (
            <p key={item.id} className="rounded-[16px] border border-border px-3 py-2">
              {item.label}
            </p>
          ))}
        </div>
      </div>
    );
  }
  return null;
}
