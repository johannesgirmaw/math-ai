"use client";

import "katex/dist/katex.min.css";
import katex from "katex";

export function MathText({ text }: { text: string }) {
  const parts = text.split(/(\$[^$]+\$)/g);
  return (
    <p>
      {parts.map((part, index) => {
        if (part.startsWith("$") && part.endsWith("$") && part.length > 2) {
          const html = katex.renderToString(part.slice(1, -1), { throwOnError: false });
          return <span key={index} dangerouslySetInnerHTML={{ __html: html }} />;
        }
        return <span key={index}>{part}</span>;
      })}
    </p>
  );
}
