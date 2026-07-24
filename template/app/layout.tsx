import type { Metadata } from "next";
import { appConfig } from "@/app.config";
import "./globals.css";

export const metadata: Metadata = {
  title: appConfig.businessName,
  description: `${appConfig.businessName} — live on the web`,
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
