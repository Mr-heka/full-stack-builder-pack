# full-stack-builder-pack

Build and deploy a real web app for your business in one sitting. One pasteable
prompt sets up GitHub + Vercel + Supabase under **your own accounts** (you sign in
once with GitHub — it chains the other two), then plain-English skills build,
change, and check on your apps. Push = deploy: every app lives at a real URL from
day one, never local-only.

## Install

The paste prompt lives in [`SETUP-PROMPT.md`](SETUP-PROMPT.md). Copy the fenced
block into Claude Code and press enter — it installs the pack, checks your machine,
and walks you to a full-screen PASS banner. From there, describe your first app in
plain English.

## What's in the pack

| Skill | What it does |
|---|---|
| `skills/foundation-check` | One prompt → PASS/FAIL table across accounts, CLIs, git identity |
| `skills/github-provision` | Detection-first GitHub connector: account, gh auth (`repo`+`workflow`), git identity from the profile |
| `skills/vercel-provision` | Detection-first Vercel connector: Hobby account via Continue-with-GitHub, CLI device-flow login, GitHub app connect |
| `skills/supabase-provision` | Supabase via GitHub SSO, org, CLI + token, smoke test |
| `skills/app-foundation-setup` | Orchestrator: check → fix → re-check until PASS |
| `skills/app-builder` | Plain English → live app: repo + Vercel link first, then scaffold, DB, push |
| `skills/app-iterate` | Change an existing app: pull → edit → safe migration → push → verify |
| `skills/app-status` | List my apps: repos, live URLs (checked live), last deploy, days live |
| `skills/deploy-doctor` | Audit-first drift doctor: findings report, click-to-change fixes |
| `modules/data-auth` | Shared module: schema/auth/storage doctrine `app-builder`/`app-iterate` follow |
| `examples/` | Three worked example builds in plain English — full conversations, end to end |
| `known-issues/` | Failure modes and workarounds |
| `template/` | The Next.js + Supabase app every build starts from |

## Conventions

Every skill in this pack follows one blessed path — one repo per app, GitHub is the
source of truth, main = production, push = deploy for code and schema. The full
doctrine lives in [`STACK.md`](STACK.md) (what the stack is and why, including the
platforms considered and rejected) and [`CONVENTIONS.md`](CONVENTIONS.md) (how the
blessed path is operated). `app-builder` injects a copy of `CONVENTIONS.md` into
every app it creates, so every generated app carries the doctrine in its own repo.

---

Made by Selr AI.
