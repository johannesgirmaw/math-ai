import type { MetadataRoute } from "next";

export default function sitemap(): MetadataRoute.Sitemap {
  const base = process.env.NEXT_PUBLIC_SITE_URL ?? "http://localhost:3000";
  return ["", "/method", "/privacy", "/terms"].map((path) => ({
    url: `${base}${path || "/"}`,
  }));
}
