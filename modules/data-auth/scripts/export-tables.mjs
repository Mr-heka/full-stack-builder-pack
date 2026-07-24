#!/usr/bin/env node
/**
 * Docker-free pre-migration export of Supabase tables to CSV + SQL.
 *
 * Runs before every destructive migration (CONVENTIONS.md #4). Talks straight
 * to the project's REST API (PostgREST) — never `supabase db dump`, which
 * shells out to a containerized pg_dump and needs Docker Desktop.
 *
 * Usage:
 *   SUPABASE_URL=https://<ref>.supabase.co \
 *   SUPABASE_SECRET_KEY=sb_secret_... \
 *   node export-tables.mjs <table> [<table> ...]
 *
 *   SUPABASE_URL falls back to NEXT_PUBLIC_SUPABASE_URL from the environment
 *   or .env.local. The secret key ("service role") comes from the Supabase
 *   dashboard (Project Settings → API keys) — pass it as an env var for this
 *   one command; never commit it, and never put it in .env.local (it is
 *   deliberately ignored there). A legacy service_role JWT works too.
 *
 * Output: exports/<UTC-timestamp>_pre-migration/<table>.csv and <table>.sql
 * (CSV for spreadsheets, SQL for Claude-assisted restore).
 */

import { mkdirSync, writeFileSync, readFileSync, existsSync } from "node:fs";
import { join } from "node:path";
import process from "node:process";
import { Buffer } from "node:buffer";

const PAGE_SIZE = 1000;

function fail(msg) {
  console.error(`✗ ${msg}`);
  process.exit(1);
}

function readEnvLocal(name) {
  if (!existsSync(".env.local")) return undefined;
  for (const line of readFileSync(".env.local", "utf8").split(/\r?\n/)) {
    const m = line.match(/^\s*([A-Za-z0-9_]+)\s*=\s*(.*)\s*$/);
    if (m && m[1] === name) return m[2].trim().replace(/^["']|["']$/g, "");
  }
  return undefined;
}

const tables = process.argv.slice(2).filter((t) => !t.startsWith("-"));
if (tables.length === 0) {
  fail("no tables given. Usage: node export-tables.mjs <table> [<table> ...]");
}
const badName = tables.find((t) => !/^[A-Za-z0-9_]+$/.test(t));
if (badName) fail(`invalid table name: ${badName}`);

const url = (
  process.env.SUPABASE_URL ??
  process.env.NEXT_PUBLIC_SUPABASE_URL ??
  readEnvLocal("NEXT_PUBLIC_SUPABASE_URL") ??
  ""
).replace(/\/+$/, "");
if (!url) {
  fail(
    "SUPABASE_URL not set (and no NEXT_PUBLIC_SUPABASE_URL in env or .env.local).",
  );
}

const key = process.env.SUPABASE_SECRET_KEY ?? "";
if (!key) {
  fail(
    "SUPABASE_SECRET_KEY not set. Get the secret key from the Supabase " +
      "dashboard (Project Settings → API keys) and pass it as an env var " +
      "for this command only — never commit it or add it to .env.local " +
      "(this script ignores it there on purpose).",
  );
}
if (key.startsWith("sb_publishable_")) {
  fail(
    "SUPABASE_SECRET_KEY is the publishable key — it authenticates, but " +
      "row-level security hides every row, so the backup would come out " +
      "empty. Use the secret key (sb_secret_...) from the Supabase " +
      "dashboard (Project Settings → API keys).",
  );
}
const jwtParts = key.split(".");
if (jwtParts.length === 3) {
  let role;
  try {
    role = JSON.parse(
      Buffer.from(jwtParts[1], "base64url").toString("utf8"),
    ).role;
  } catch {
    role = undefined;
  }
  if (role && role !== "service_role") {
    fail(
      `SUPABASE_SECRET_KEY is a legacy "${role}" JWT — it authenticates, but ` +
        "row-level security hides every row, so the backup would come out " +
        "empty. Use the service_role key from the Supabase dashboard " +
        "(Project Settings → API keys).",
    );
  }
}

const headers = { apikey: key, Authorization: `Bearer ${key}` };

async function fetchJson(path, extraHeaders = {}) {
  const res = await fetch(`${url}${path}`, {
    headers: { ...headers, ...extraHeaders },
  });
  if (!res.ok) {
    const body = await res.text().catch(() => "");
    throw new Error(`HTTP ${res.status} on ${path}: ${body.slice(0, 300)}`);
  }
  return res;
}

/** PostgREST's OpenAPI root, fetched once for the whole run. */
let openApiSpec;
async function openApi() {
  if (!openApiSpec) {
    const res = await fetchJson("/rest/v1/");
    openApiSpec = await res.json();
  }
  return openApiSpec;
}

/** Column definitions from PostgREST's OpenAPI root. */
async function tableColumns(table) {
  const spec = await openApi();
  const def = spec.definitions?.[table];
  if (!def) {
    const known = Object.keys(spec.definitions ?? {}).join(", ") || "(none)";
    throw new Error(`table "${table}" not found. Known tables: ${known}`);
  }
  const required = new Set(def.required ?? []);
  return Object.entries(def.properties ?? {}).map(([name, p]) => ({
    name,
    format: p.format ?? p.type ?? "text",
    notNull: required.has(name),
    isPk: /Primary Key/i.test(p.description ?? ""),
  }));
}

async function tableRows(table, columns) {
  const orderBy = (columns.find((c) => c.isPk) ?? columns[0])?.name;
  const order = orderBy ? `&order=${encodeURIComponent(orderBy)}.asc` : "";
  const rows = [];
  let from = 0;
  for (;;) {
    const res = await fetchJson(`/rest/v1/${table}?select=*${order}`, {
      Range: `${from}-${from + PAGE_SIZE - 1}`,
      "Range-Unit": "items",
      Prefer: "count=exact",
    });
    const page = await res.json();
    rows.push(...page);
    from += page.length;
    const total = Number(
      (res.headers.get("content-range") ?? "").split("/")[1],
    );
    if (Number.isFinite(total)) {
      // The server caps every response at its own max-rows setting (Supabase
      // dashboard: API Settings → Max Rows), which can be smaller than
      // PAGE_SIZE — a short page is NOT proof the table is exhausted. Only
      // the reported total says when the backup is complete.
      if (rows.length >= total) return rows;
      if (page.length === 0) {
        throw new Error(
          `server stopped returning rows at ${rows.length} of ${total} — ` +
            `the backup would be incomplete`,
        );
      }
    } else if (page.length < PAGE_SIZE) {
      // No usable total (count=exact not honored): a short page is the only
      // end-of-table signal available.
      return rows;
    }
  }
}

function csvCell(v) {
  if (v === null || v === undefined) return "";
  let s = typeof v === "object" ? JSON.stringify(v) : String(v);
  if (typeof v === "string" && /^[=+\-@\t\r]/.test(s)) s = `'${s}`;
  return /[",\r\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
}

function toCsv(columns, rows) {
  const names = columns.map((c) => c.name);
  const lines = [names.map(csvCell).join(",")];
  for (const row of rows) {
    lines.push(names.map((n) => csvCell(row[n])).join(","));
  }
  return lines.join("\r\n") + "\r\n";
}

function sqlLiteral(v) {
  if (v === null || v === undefined) return "NULL";
  if (typeof v === "number") return String(v);
  if (typeof v === "boolean") return v ? "true" : "false";
  const s = typeof v === "object" ? JSON.stringify(v) : String(v);
  return `'${s.replace(/'/g, "''")}'`;
}

function toSql(table, columns, rows) {
  const names = columns.map((c) => c.name);
  const header = [
    `-- Pre-migration export of "${table}" — ${rows.length} rows`,
    `-- Exported ${new Date().toISOString()} via PostgREST (Docker-free)`,
    `-- Approximate original shape (from the REST schema; restore is`,
    `-- Claude-assisted — a post-drop restore needs schema surgery):`,
    ...columns.map(
      (c) =>
        `--   ${c.name} ${c.format}${c.notNull ? " not null" : ""}${c.isPk ? " (primary key)" : ""}`,
    ),
    `-- (values round-tripped through JSON — integers beyond 2^53 lose exactness)`,
    "",
  ];
  const inserts = [];
  for (let i = 0; i < rows.length; i += 100) {
    const batch = rows.slice(i, i + 100);
    const values = batch
      .map((r) => `  (${names.map((n) => sqlLiteral(r[n])).join(", ")})`)
      .join(",\n");
    inserts.push(
      `insert into "${table}" (${names.map((n) => `"${n}"`).join(", ")}) values\n${values};`,
    );
  }
  if (rows.length === 0) inserts.push(`-- (table was empty)`);
  return header.join("\n") + "\n" + inserts.join("\n\n") + "\n";
}

const stamp = new Date()
  .toISOString()
  .replace(/[:T]/g, "-")
  .replace(/\..+$/, "");
const outDir = join("exports", `${stamp}_pre-migration`);

let totalRows = 0;
for (const table of tables) {
  try {
    const columns = await tableColumns(table);
    const rows = await tableRows(table, columns);
    mkdirSync(outDir, { recursive: true });
    writeFileSync(join(outDir, `${table}.csv`), toCsv(columns, rows));
    writeFileSync(join(outDir, `${table}.sql`), toSql(table, columns, rows));
    totalRows += rows.length;
    console.log(`✓ ${table}: ${rows.length} rows → ${outDir}/${table}.{csv,sql}`);
  } catch (err) {
    fail(`export of "${table}" failed — do NOT push the migration. ${err.message}`);
  }
}

console.log(`✓ export complete: ${tables.length} table(s), ${totalRows} row(s), ${outDir}`);
