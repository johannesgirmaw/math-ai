import type { Metadata } from "next";
import { Inter, Montserrat } from "next/font/google";
import "./globals.css";

const inter = Inter({ subsets: ["latin"], variable: "--font-inter" });
const montserrat = Montserrat({
  subsets: ["latin"],
  weight: "700",
  variable: "--font-montserrat",
});

const siteUrl = process.env.NEXT_PUBLIC_SITE_URL ?? "http://localhost:3000";
const description = "Intelligent systems rooted in precise mathematical logic.";

export const metadata: Metadata = {
  metadataBase: new URL(siteUrl),
  title: { default: "MATH SI", template: "%s · MATH SI" },
  description,
  openGraph: {
    title: "MATH SI",
    description,
    url: siteUrl,
    siteName: "MATH SI",
  },
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      <body className={`${inter.variable} ${montserrat.variable} antialiased`}>{children}</body>
    </html>
  );
}
