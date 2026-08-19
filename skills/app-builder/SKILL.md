---
name: app-builder
description: The pack's flagship — turns a plain-English description of a business app into a live one. Mini-plan first (business name, owner email, intended use), then GitHub repo + Vercel link created BEFORE any feature code exists, scaffold copied from the pack's template/ folder, the app's own Supabase project (project-count check and business-use gate fire before creation), a committed migration, and one git push that deploys code and schema together. Done only when the pushed commit auto-deployed, the live URL returns 200, the migration applied, and the owner's magic-link sign-in works. Use when an attendee describes a new app they want built; every run ends with the next-steps card. NOT for changing an app that already exists (app-iterate) or listing/sharing apps (app-status).
---

# app-builder

Builds one app, end to end, on the blessed path (`CONVENTIONS.md`) — plain English in, a live URL
the owner can put on their phone out. The attendee never sees a framework decision, a deploy
command, or a second way of doing anything: one repo, one Vercel project, one Supabase project,
push = deploy. The structural promise this skill exists to keep: **the repo and the deploy
connection are created before any feature code is written**, so a local-only app is impossible, not just
discouraged.

## Routing — the M2 trio

| The attendee says | Skill |
|---|---|
| "Build me an app that…" — an app that doesn't exist yet | **this skill** |
| "Change / add / fix …" on an app that already exists | `app-iterate` |
| "What apps do I have?" / "how do I share it?" / "is it still up?" | `app-status` |

Three skills, no modes. An iterate ask arriving mid-build still belongs here until this skill's
done-check passes; after that, every change is `app-iterate`.

## Scope — what v1 builds, and what it refuses

**In:** DB-backed CRUD, forms and lead capture, booking, job trackers, simple dashboards.
Single-tenant — the app serves the attendee's one business. Sign-in is the module's owner-only
magic link (`modules/data-auth/MODULE.md`): one address, no passwords. "Customers can log in" is
an explicit later step gated behind custom SMTP — never a scaffold default, because the built-in
mailer would silently drop every customer's link.

**Refused, with the redirect said in plain English — never improvised around:**

| Ask | Say this |
|---|---|
| Taking payments in the app (checkout, cards, "integrate Stripe") | "The app won't handle payments itself — card handling brings compliance and liability a workshop app shouldn't carry. The working shortcut: create a **payment link in your Stripe dashboard** and we paste it into the app as a button. Same money arrives, none of the risk lives in your code." |
| A native mobile app (App Store / Play Store) | "What we build is a website that works properly on the phone — open it, share it, add it to the home screen and it behaves like an app. App-store builds are a different, much heavier project." |
| Multi-tenant SaaS ("other businesses could sign up and use this") | "This pack builds the app **for your business**. A product other businesses sign up for is a real software venture — different architecture, billing, support. Let's make yours work for you first." |
| Real-time collaboration (live cursors, two people editing at once) | "The app shows fresh data every time you open or refresh a page, and for a small team that's what actually gets used. Live simultaneous editing is heavy machinery we deliberately leave out." |

## Before this skill

Foundation is green: the full registry passes (`foundation-check`, all 16 checks — accounts,
CLIs, git identity, Supabase org) **and** `vercel-provision`'s VC-APP holds (the Vercel GitHub
app, which lives outside the registry). `app-foundation-setup` gets it there. This skill never
provisions accounts and never re-negotiates identity; any auth check failing routes to its
provisioner per the registry's mapping.

## This skill never drives a browser

Claude's access to GitHub, Vercel and Supabase here comes from the sign-ins `app-foundation-setup`
already made in the CLIs — `gh`, `vercel`, `supabase` — so no sign-in in this skill is Claude's to
perform. The dashboard touchpoints are **owner-only**: Claude hands the link over — a
`browser-connect` rung-1 pinned open into the owner's daily browser profile, which is opening a
page for them, not driving — the owner clicks, signed in as themselves, and reads back the one
thing that proves it took —

- **Supabase → Project Settings → Integrations → GitHub** (step 4) — after a reload the section
  shows the connected repo and a **Disable integration** button.
- **Supabase → Auth → URL Configuration** (step 4) — Site URL is the production URL, and
  `http://localhost:3000` is listed under Redirect URLs.
- **The Vercel project's Domains settings** (step 3) — the production domain, read back exactly as
  it is written there.
- **Widening the Vercel or Supabase GitHub app's repository access** (steps 3–4) — the install
  lists the owner's own account with **All repositories**.

So Claude drives no browser: there is no automation profile to tear down and no credential window
to hold, because Claude signs in to nothing here. The sign-ins the skill does involve are the
owner's own — step 6's proof 4, the magic link into their own app, and the dashboard session the
touchpoints above assume — and neither needs a profile or a credential window. This skill's line in
the driven-browser report is always the same one — **no browser driven**. Browsers get
driven during provisioning, under the provisioners' own "Consent and the credential window" contract
([`supabase-provision`](../supabase-provision/SKILL.md#consent-and-the-credential-window),
[`vercel-provision`](../vercel-provision/SKILL.md#consent-and-the-credential-window)); this skill
neither restates that contract nor needs it.

A **teardown FAILED** line carried in from the foundation run stays advisory here, exactly as
`app-foundation-setup` has it: a report line, not a check. It never becomes a fifth proof in step 6
and it turns none of the four red — with all four green the build is verified and convention 3's
three conditions are met in full. What is outstanding is the machine, not the app. While that
profile is still sitting there, say the line again with the full path and what the owner must delete
before they leave, say plainly that the app is built and that cleanup is not, and don't close the
run with the word *done*. That is deliberately stricter than `app-foundation-setup`, which only
repeats the line after its banner: a leftover automation profile is a credential window left open,
and *done* said over it is what stops anyone going back for it.

## Steps

**1. Mini-plan.** One screen, in the attendee's own words, approved before anything is created:

- **What the app does** — mapped to the In list; a refused ask gets its redirect here, not later.
- **The business name** — fills the template's `businessName` slot (page heading, tab title).
- **The owner email** — fills `ownerEmail`; it must be the address the owner signs into Supabase
  with (the module's org-member rule). A different address ⇒ custom SMTP first; offer to build
  with the Supabase address today and widen later.
- **Intended use — evaluation or business.** Evaluation = showing family and friends. Business =
  customers will use it, it gets linked from the site, or it gets promoted. This answer arms the
  gate in step 2.
- **The first tables** — one or two, named in business words ("jobs", "enquiries"). More waits
  for `app-iterate`.

The mini-plan closes with the same fixed question every time — **"Happy for me to build
this?"** — and the yes that follows is the approval everything after stands on. The wording is
fixed for the same reason as step 6's proof labels: the worked examples (`examples/`) quote it
and the maintainers' nightly QA fixtures key on it.

**2. Gate — business use on free tier.** Fires when the mini-plan says business use. Name both
upgrades together, once, before anything exists (convention 6's business-use trigger; `STACK.md`
carries the Vercel-tier rationale): **Vercel Pro, $20/mo** and **Supabase Pro, $25/mo plus
usage-based compute, never quoted flat**. The choice is the owner's: **(a)** evaluate free
first — personal audience only, days not months, upgrade before any customer traffic — or
**(b)** upgrade now. Record the
answer in the mini-plan and carry it into the next-steps card. Never silently proceed past this
question; evaluation-use apps skip the gate but still get the Pro-by-default line at the end.

**3. Repo + Vercel link — before any feature code.** Work from a short base directory (`~/apps`) —
deep paths break Next.js production builds on Windows (path-length limit).

```sh
cp -R ~/.claude/skills/full-stack-builder-pack/template <app-slug>
cd <app-slug>
cp ~/.claude/skills/full-stack-builder-pack/CONVENTIONS.md .
git init -b main && git add -A && git commit -m "app template"
gh repo create <owner>/<app-slug> --private --source . --push
vercel link --yes        # creates the Vercel project under the owner's account
vercel git connect       # repo → project; this is what makes push = deploy real
```

`<app-slug>` is the kebab-cased app name; one repo per app, private, born under the owner's own
account from the pack's `template/` (convention 1). The template is copied **out** of the pack
install and only ever built there — never `npm install` or `npm run build` inside
`~/.claude/skills/`. The copy must land in a fresh `<app-slug>` directory — `cp -R` into one that
already exists nests `template/` inside it; on a retry, delete the partial directory and re-copy.
The owner reads the project's real production domain out of the Vercel project's Domains settings
— never assume `<slug>.vercel.app` survives the global namespace. `vercel git connect` saying it
can't access the repository means the Vercel GitHub app can't see the new private repo: the owner
sets the installation's repository access to **All repositories** (github.com/settings/installations
→ Vercel — the blessed scope, `vercel-provision`), then Claude re-runs it. Both are dashboard
touchpoints, so both are owner-only. Never `vercel deploy`, here or anywhere.

**4. Supabase project — count first, then create, then wire.** This step deliberately precedes
the scaffold: the count gate must be able to stop the build before any feature code is written, and step 5's
`npm run build` needs the env vars this step writes.

- **Count:** `supabase projects list` — active projects in the owner's org against the free-tier
  cap (~2 per org, convention 6). **At the cap → stop.** The way forward is Supabase Pro
  ($25/mo plus usage-based compute) and that upgrade is the owner's decision, not a side effect
  of building an app. No project is created until they've made it. Stopping here leaves step 3's
  repo and Vercel link in place — correct and free; never delete them. The build resumes from
  this step once the owner has decided.
- **Create:** `supabase projects create <app-slug> --org-id <org> --region ap-southeast-2
  --db-password <generated>` (Sydney default; override for a remote attendee). Generate the
  database password, hand it to the owner to store in their password manager, and keep it
  nowhere else — the blessed path never uses it day to day.
- **Wire push = deploy for schema** (dashboard, once — owner-only, in their own browser; this
  skill drives none): Project Settings → Integrations → GitHub → connect the repo, working
  directory `.`, enable **Deploy to production** on `main`. Free-plan feature (module doctrine).
  The enable only counts when it survives a reload — the owner reads back that the section shows
  the connected repo and a **Disable integration** button. The Supabase GitHub app may also need
  repository access widened, same move as Vercel's. The integration applies migrations on pushes
  made **after** it exists; if it was wired after a push, trigger it:
  `git commit --allow-empty -m "apply migrations" && git push`.
- **Auth URLs** (dashboard, once — owner-only, same as above): Auth → URL Configuration → Site
  URL = the production URL from step 3; add `http://localhost:3000` to Redirect URLs.
- **Env vars live in Vercel** (convention 5): from `supabase projects api-keys --project-ref
  <ref>`, add `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` (the publishable
  key) to the Vercel project for production, preview and development; then
  `vercel env pull .env.local`. No hand-maintained `.env`, no secrets in the repo.

**5. Scaffold the app.** Fill `app.config.ts` — `businessName`, `ownerEmail` — from the
mini-plan. Build the mini-plan's feature and nothing more: pages under `app/`, the template's
`lib/supabase/` clients, and the schema as a migration file
`supabase/migrations/<YYYYMMDDHHmmss>_<slug>.sql` (UTC timestamp) per the module — additive on a
fresh app, committed to the repo, never applied by dashboard or CLI. `npm install` and
`npm run build` must be green locally before anything is pushed.

The template's `/up` route (`app/up/page.tsx`) is not part of any feature and is never edited or
removed: it is `force-static` and excluded from `proxy.ts`'s matcher so the day-30 sweep can ping
it without waking the database (step 7). `npm run build`'s route table must keep printing `○ /up`
— a `ƒ` there means something wired it to a dynamic API, and the card's day-30 promise has stopped
being true.

**6. Push = deploy — then verify all four.** Commit and `git push` (to `main`; there is no other
branch). Then prove it, in order:

1. **The push auto-deployed:** poll `vercel ls <project> --prod` until the new deployment is
   **Ready** — a build still in flight already carries the right SHA, so checking the SHA alone can
   pass mid-build — then check it built the pushed commit:
   `vercel api /v13/deployments/<deployment-host>` → `meta.githubCommitSha` equals
   `git rev-parse HEAD`. Pass the host with no scheme; `vercel ls` prints the full URL, so strip the
   `https://`. Run `vercel api` from PowerShell on Windows, since Git Bash rewrites the leading `/`.
   `vercel inspect`'s default output prints status, aliases and builds but no commit SHA, which is
   why the SHA is read from the API here. A live URL without that SHA is not continuous
   deployment — it's the failure mode this pack exists to prevent.
2. **Live URL returns 200** — the production domain, not a deployment preview URL.
3. **The migration applied:** probe the REST API for the new table
   (`GET <SUPABASE_URL>/rest/v1/<table>?select=*&limit=1` with the publishable key → 200).
   The apply runs about a minute behind the push — poll; a 404 that never clears means it did
   not run. URL 200 alone never counts (convention 3).
4. **Owner magic-link sign-in works:** the module's smoke test — the owner does both halves in
   **their own browser**: they open `/login` and send the link to `ownerEmail` themselves, then
   open the email in that same browser (the default-mailer link only works in the browser it
   was requested from; Claude never reads their inbox), landing signed-in on `/owner`. Tell the
   owner what to look for: the **first** sign-in email is titled "Confirm your email address"
   (it creates their auth user) — only later ones say sign-in.

Each proof is announced as it passes, opening with its fixed label — **"Proof 1 of 4 —
deployed by the push"**, **"Proof 2 of 4 — the app is live"** (the production URL and its 200
in the same breath), **"Proof 3 of 4 — the database is ready"**, **"Proof 4 of 4 — owner
sign-in works"**. The labels are fixed so the worked-example transcripts (`examples/`) and the
maintainers' nightly QA fixtures can quote and key on them; the sentence after each
label is free.

All four pass and the build is verified — convention 3's "done" in full. Any failure is fixed and
re-verified, not talked around. One thing can still be outstanding with all four green: a teardown
FAILED line carried in from the foundation run — advisory, never a fifth proof, and while that
profile is still on the machine the run isn't closed with the word *done*
([above](#this-skill-never-drives-a-browser)).

**7. Next-steps card — every run, all slots.** From the app repo:

```sh
node ~/.claude/skills/full-stack-builder-pack/skills/app-builder/scripts/next-steps.mjs \
  --url <production-url> --name "<business name>" --business-use yes|no
```

Renders [next-steps.md](next-steps.md) with every slot filled — live URL, in-terminal QR code,
personal-audience share blurb, the change-it line (`app-iterate`), the Pro-by-default cost
line, the auto-pause warning, the custom-domain stopgap, the day-30 consent line, the Loop
line — and exits non-zero if any slot is left unfilled or any of those fixed sections is
missing from the template. Show the attendee the whole card; no slot is optional.

The card's day-30 line promises the check-in **neither reads your data nor wakes the database**,
and the template's `/up` route is what makes that true: `force-static` and outside `proxy.ts`'s
matcher, so a HEAD of `<production-url>/up` is answered by prerendered HTML that runs no Supabase
client at all. The sweep pings that route — never the home page, which is `force-dynamic` and
calls Supabase on every render, and convention 6 is explicit that a DB-touching ping resets the
idle timer and fakes its own evidence. That HEAD plus the management-API status read the same line
describes is the whole check-in.

## Rules quoted from CONVENTIONS.md

- **Convention 1** — one repo per app, born from the pack's `template/`, private, under the
  owner's own account; repo + Vercel link exist before any code is scaffolded.
- **Convention 2** — `main` is production; main-only, no branches, no PRs.
- **Convention 3** — push = deploy for code **and** schema; never `vercel deploy`; never deploy
  from an unlinked directory; schema changes only from committed migrations; "done" = pushed
  commit auto-deployed + live URL 200 + migration applied.
- **Convention 6** — one Supabase project per app; both free-tier cliffs quoted up front — the
  project cap (→ Pro, $25/mo plus usage, never flat) and auto-pause (~1 week idle). Its day-30
  rule — a static route plus a management-API status check, because a DB-touching ping resets the
  idle timer — is why the template ships `/up` and why step 7's card can promise what it does.
- **Convention 8** — everything is born under the owner's accounts; nothing under Selr's.
- **What is off-path** — a deploy-target or workflow ask outside the path (Netlify, keep it
  local, dashboard SQL, a staging branch, …) gets that table's redirect, opened with the fixed
  words **One blessed path** and naming `CONVENTIONS.md`.
- **`STACK.md`, the Vercel tier stance** — Hobby is a short, personal-audience evaluation
  window; Pro before any business use; step 2's gate is that enforcement.

## Data + auth

`modules/data-auth/MODULE.md` owns everything database-shaped — migration naming,
additive-vs-destructive rules, the owner-only magic-link gates, the storage-bucket pattern, the
Docker-free export. Steps 4–6 carry the module's actions in run order so a build never has to
leave this file; `MODULE.md` holds the canonical form, and where the two diverge, `MODULE.md`
wins.

## Not this skill

- Changing an app that already passed step 6 — `app-iterate` (including every
  customer-login/SMTP ask after build day).
- Listing apps, share help, still-alive checks — `app-status`.
- Accounts, CLIs, SSO, the Supabase org — `github-provision` / `vercel-provision` /
  `supabase-provision`, orchestrated by `app-foundation-setup`; pre-flight verdicts are
  `foundation-check`.
- Post-deploy drift and stray deploys, on any app — `deploy-doctor`.
- CWK's `deploy-to-vercel` (or any generic deploy/hosting skill) — the pack deploys only by
  pushing to `main` (convention 3); building or deploying a workshop app routes here, never to
  a CLI-deploy skill.
- Custom domains — a planned future skill; the next-steps card carries the stopgap line.
