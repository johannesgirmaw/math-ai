import { readFile } from "node:fs/promises";
import { join } from "node:path";
import { ImageResponse } from "next/og";

export const size = { width: 1200, height: 630 };
export const contentType = "image/png";
export const runtime = "nodejs";

export default async function OpenGraphImage() {
  const icon = await readFile(join(process.cwd(), "src/app/icon.png"));
  const src = `data:image/png;base64,${icon.toString("base64")}`;
  return new ImageResponse(
    <div
      style={{
        background: "#F4F8F9",
        width: "100%",
        height: "100%",
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
      }}
    >
      <img src={src} alt="" height={340} />
      <div style={{ color: "#005F73", fontSize: 64, letterSpacing: 14, marginTop: 8 }}>MATH SI</div>
    </div>,
    { ...size },
  );
}
