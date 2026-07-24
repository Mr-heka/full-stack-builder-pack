#!/usr/bin/env node
/**
 * Renders the app-builder next-steps card (../next-steps.md) with every slot
 * filled, and refuses to render a partial card: any {{SLOT}} left over, or any
 * of the card's fixed sections missing from the template, exits 1.
 *
 *   node next-steps.mjs --url https://my-app.vercel.app --name "Sunnybank Lawns" --business-use no
 *
 * --url          the app's production URL (the real domain, read from Vercel)
 * --name         the business name (the template's businessName slot)
 * --business-use yes|no — the mini-plan's intended-use answer; picks the cost line
 * --no-qr        skip the QR code (QA fixtures / terminals that can't draw it)
 *
 * The QR is drawn in-terminal via `npx qrcode-terminal` (Node is guaranteed by
 * the CLI-NODE foundation check). If npx fails the card still renders, with a
 * visible note in the QR slot — a missing QR must never eat the whole card.
 */
import { readFileSync } from "node:fs";
import { spawnSync } from "node:child_process";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

function arg(name) {
  const i = process.argv.indexOf(`--${name}`);
  return i === -1 ? undefined : process.argv[i + 1];
}
const url = arg("url");
const name = arg("name");
const businessUse = arg("business-use");
const noQr = process.argv.includes("--no-qr");

if (!url || !name || !["yes", "no"].includes(businessUse)) {
  console.error(
    'Usage: node next-steps.mjs --url <production-url> --name "<business name>" --business-use yes|no [--no-qr]'
  );
  process.exit(1);
}
if (!/^https:\/\/[A-Za-z0-9._~\-/%]+$/.test(url)) {
  console.error(`--url must be a bare https production URL (no query string or shell metacharacters): ${url}`);
  process.exit(1);
}

const PRO_LINES = {
  yes:
    "You said this app is for the business. Before customers touch it, move both plans to " +
    "paid: **Vercel Pro ($20/month)** and **Supabase Pro ($25/month plus usage-based " +
    "compute — the bill scales with real use)**. That's the default recommendation, not " +
    "fine print: the free tiers are an evaluation window measured in days, and business " +
    "traffic on them breaks both the rules and, eventually, the app.",
  no:
    "While you're evaluating — showing your people, kicking the tyres — the free tiers are " +
    "fine. The day this app starts working for the business (customers using it, linked " +
    "from your site, promoted anywhere), move to **Vercel Pro ($20/month)** and **Supabase " +
    "Pro ($25/month plus usage-based compute)** first. Pro by default for anything " +
    "business-facing.",
};

function qrBlock() {
  if (noQr) return "(QR skipped — open the link above on your phone.)";
  // The bin takes argv when run from a TTY, stdin otherwise — feed both.
  const r = spawnSync("npx", ["-y", "qrcode-terminal@0.12.0", url], {
    encoding: "utf8",
    input: `${url}\n`,
    shell: process.platform === "win32",
    timeout: 60_000,
  });
  const out = (r.stdout ?? "").trimEnd();
  if (r.status === 0 && out.length > 0)
    return `${out}\n\nPoint your phone's camera at the square and it opens.`;
  console.error(`[next-steps] QR generation failed (${r.error?.message ?? `exit ${r.status}`}) — rendering without it.`);
  return "(QR unavailable on this machine — open the link above on your phone.)";
}

const templatePath = join(dirname(fileURLToPath(import.meta.url)), "..", "next-steps.md");
const card = readFileSync(templatePath, "utf8")
  .replaceAll("{{BUSINESS_NAME}}", () => name)
  .replaceAll("{{LIVE_URL}}", () => url)
  .replaceAll("{{PRO_LINE}}", () => PRO_LINES[businessUse])
  .replaceAll("{{QR}}", () => qrBlock());

const leftover = card.match(/\{\{[A-Z_]+\}\}/g);
if (leftover) {
  console.error(`[next-steps] unfilled slots: ${[...new Set(leftover)].join(", ")}`);
  process.exit(1);
}

// The prose sections are as mandatory as the slots — a template edit that drops
// one must fail the render, not ship a thinner card.
const REQUIRED_SECTIONS = {
  "live URL": "**Your app:**",
  "share blurb": "Share it — to your people, for now",
  "change-it line": "app-iterate",
  "cost line": "The money, straight:",
  "auto-pause warning": "goes to sleep after about a week",
  "custom-domain stopgap": "ten-minute job",
  "day-30 consent line": "Day-30 check-in",
  "Loop line": "Ask us for an invite",
};
const flatCard = card.replace(/\s+/g, " "); // markers must survive prose re-wrapping
const missing = Object.entries(REQUIRED_SECTIONS)
  .filter(([, marker]) => !flatCard.includes(marker))
  .map(([label]) => label);
if (missing.length) {
  console.error(`[next-steps] card is missing required sections: ${missing.join(", ")}`);
  process.exit(1);
}
process.stdout.write(card);
