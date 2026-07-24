# CONVENTIONS.md — the one blessed path

> **Locked (2026-07-20).** The canonical
> copy of this file lives at the root of `lukeselr/full-stack-builder-pack`; `app-builder`
> injects a copy into every app it creates, so every generated app carries the doctrine in its own
> repo. Pack skills and `deploy-doctor` quote this file; nobody owns a drifting copy.

Every skill in this pack follows one path. Not "a recommended path" — the only one. The pain this
solves is *six deploy targets and no continuous deploy*; a second blessed way recreates it inside our
own skills. When an attendee asks for something off-path, the skill redirects here in plain English
rather than improvising.

**Scope tags.** Paid company trainings are being sold now, so each convention below is tagged for
whether it survives a company-training variant unchanged:

| Tag | Meaning |
|---|---|
| **[Org-compatible]** | The rule's *invariant* holds identically for an individual attendee and a company; a v2 company variant inherits the invariant as-is. The variant may generalize the owner from a person to an org, or layer company process on top — where it does, the convention's company extension names what changes and the invariant that carries over unchanged. |
| **[Individual]** | Written for an attendee who owns their own accounts. A company variant *extends* it: only the extension point named in the convention may be substituted (org ownership, IT policy, who pays); the invariant carries over unchanged. |

Open company-variant questions (account ownership, who pays Pro, IT policy) remain business decisions
(deep-dive agenda #4). They are recorded, not resolved, here.

---

## 1. One repo per app. GitHub is the source of truth. **[Org-compatible]**

Every app is exactly one GitHub repository. The repo is what exists; a working directory on a laptop
is a cache of it. If it is not pushed, it does not exist.

- Repos are born from the pack's `template/` folder: `app-builder` copies it out of the local pack
  install, injects the pack's `CONVENTIONS.md`, then `git init` + `gh repo create <owner>/<app>
  --private --source . --push`. The config slots (`app.config.ts`) are filled at the scaffold
  step, after the repo exists. The attendee's copy is born **private under their own account**.
  Copying `template/` out by hand is the human fallback.
- The repo is created **before any code is scaffolded** — `app-builder`'s repo + Vercel-link step
  precedes its scaffold step. This is what makes "never local-only" structural rather than a promise
  in prose.
- Never a second app inside an existing app's repo. Never two Vercel projects on one repo.

*Company extension:* repo owner may be a GitHub organisation instead of the attendee's personal
account. Everything else — one repo per app, template instantiation, private by default — is unchanged.

## 2. `main` is production. Main-only. **[Org-compatible]**

There is one long-lived branch: `main`. No feature branches, no pull requests, no preview
deployments in v1. Attendees commit to `main` and push.

This is deliberate. Branch/PR flow is the single largest source of "I'm stuck and I don't know what
state my code is in" for a non-technical owner. The recovery story (convention 4) is what buys the
right to skip it.

*Company extension:* a company with an existing review policy can add PR flow on top — the pack's
rules about push-triggered deploy and committed migrations still hold on whatever branch is
production. v1 skills assume `main`.

## 3. Push = deploy — for code **and** schema. **[Org-compatible]**

`git push` to `main` is the one and only deploy action.

- **Code:** Vercel builds and deploys the app from the push.
- **Schema:** Supabase's GitHub-linked deploy applies committed migrations from the repo on push to
  `main`. This is available on the free plan.

Rules that follow from this:

- **Never `vercel deploy`.** A CLI deploy produces a live URL while continuous deployment was never
  actually wired up — the check passes and the attendee is stranded the next time they change
  something. Skills deploy by pushing, always.
- **Never deploy from an unlinked directory.** A CLI deploy from a directory with no linked Vercel
  project silently **creates a second Vercel project** for the app — a convention 1 violation on top
  of the CLI-deploy one.
- **Committed-migrations rule: the database schema never changes except from a migration file
  committed to the repo.** No ad-hoc SQL in the Supabase dashboard, no CLI push of uncommitted
  migrations. The repo is the schema's source of truth exactly as it is the code's.
- **"Done" means the pushed commit auto-deployed, the live URL returns 200, and the migration
  actually applied** — not just that a URL responds. Skills verify the migration post-push, not only
  the HTTP status.

Applied-vs-committed schema parity is a standing drift check owned by `deploy-doctor`.

## 4. The undo is Vercel one-click rollback — **code only**. **[Org-compatible]**

When a change breaks the live app, the recovery move is Vercel's one-click rollback to the previous
deployment. It is instant, it needs no git knowledge, and it is what makes main-only safe.

**Rollback is a stopgap, not the end state.** After a rollback, Vercel switches off automatic
production deploys: new pushes to `main` still build, but they do **not** go live until the rollback
is undone. The follow-through is therefore always both halves — Claude pushes a fix or revert commit
to `main`, **and** the rollback is undone (the dashboard's **Undo Rollback**, or `vercel promote`) so
push = deploy resumes. `vercel promote` used to undo a rollback is sanctioned: it restores push =
deploy rather than bypassing it, and the M4 anti-pattern matchers, when they are written, must exempt
this use. Until the follow-through lands, the app sits in a named drift state — **rolled back with
auto-deploy off** — which belongs to `deploy-doctor`'s drift library.

The button also reaches exactly **one step back** on the free plan — the immediately previous
production deployment, no further. If the last two pushes were both bad, the recovery is a
Claude-assisted revert commit pushed to `main`, not the button.

Be honest about its limit: **rollback restores code, not data.** A migration that dropped a column is
not undone by rolling back the deployment.

Data recovery is a separate, weaker guarantee:

- Additive migrations (new tables, new nullable columns) apply silently.
- **Destructive** migrations (drop, rename, type-narrowing, row deletes) require a plain-English
  confirmation naming exactly what will be lost, plus an **automatic pre-migration export** of the
  affected tables to SQL/CSV over a direct Postgres/API connection. No Docker — attendee laptops do
  not get Docker Desktop.
- **The default: anything not provably additive is treated as destructive.** The two lists above are
  examples, not a partition.
- The confirm and the export happen **before** the push, since the push is what applies the migration.
- Recovery from that export is **Claude-assisted restore**, not one-click. A post-drop restore needs
  schema surgery. Say so; do not promise an undo button for data.

## 5. Environment variables live in Vercel. **[Individual]**

Vercel is where env vars are defined and where production reads them. Locally, `vercel env pull`
writes `.env.local`. `.env.local` is git-ignored and never committed — no secrets in the repo, ever.

- One source, not two. Do not maintain a parallel `.env` by hand.
- Supabase keys reach the app through Vercel's env vars; key drift between Supabase and Vercel is a
  first-class `deploy-doctor` check.

*Company extension:* a company may require a managed secrets store or restrict who can read
production env vars. The extension point is *where the values live*; the invariant — exactly one
source, and secrets never committed to the repo — carries over unchanged.

## 6. One Supabase project per app — and two free-tier cliffs. **[Individual]**

Each app gets its own Supabase project. Shared projects across apps make every later change a
blast-radius question.

Two free-tier limits will be hit, and both are quoted up front rather than discovered in production:

**Cliff 1 — project cap.** The free tier allows roughly **two active projects per organisation**.
One project per app therefore means the **third app** triggers **Supabase Pro** — business use
triggers it earlier, per the business-use trigger below. Pro is **$25/mo plus usage-based compute**
beyond the included quota. **Never quote it as a flat $25.** `app-builder` checks the project count
before creating a new one and surfaces the upgrade decision at that moment, not after.

**Cliff 2 — auto-pause.** Free projects **auto-pause after roughly one week of inactivity**. A paused
project returns opaque 500s, and this is the single most likely post-workshop "my app broke" event.
Consequences baked into the pack:

- Pause detection is a first-class check in `deploy-doctor`'s drift library.
- `app-status` warns pre-emptively ("your app may sleep soon"). Supabase exposes pause *status*
  through the management API but no inactivity timer, so the warning combines that status check
  with a heuristic anchored to the last deploy (or pack-side activity tracking) — never a precise
  countdown.
- Unpause guidance ships in the next-steps template and the instructor runbook.
- A day-30 still-live sweep must use a static route / HEAD request plus a **management-API status
  check** — a DB-touching ping resets the idle timer and fakes its own evidence, and the HEAD
  request alone cannot see a paused database.

**The business-use trigger — stated once, here; `STACK.md` and the skills reference it rather than
restate it.** The first app the business actually uses or promotes triggers **both** upgrades,
unconditionally: **Vercel Pro ($20/mo)**, because Vercel Hobby is a short, personal-audience
evaluation window only (see `STACK.md`), and **Supabase Pro**, because a business app cannot
tolerate free-tier auto-pause (cliff 2). Both are named together at the business-use gate so the
owner sees the real running cost once.

*Company extension:* projects sit under a company Supabase organisation and Pro is almost certainly
already in play, which removes cliff 1 and (on Pro) cliff 2. One project per app is unchanged.

## 7. GitHub SSO chains all identity — so the GitHub account is hardened. **[Individual]**

Attendees sign in to **Vercel and Supabase with GitHub**. One account to create, one to protect,
instead of three sets of credentials on a workshop laptop.

This is an accepted single point of failure, and it is paid for with hard requirements on the GitHub
account:

1. **A business email address the owner controls** — not a colleague's, not a shared inbox.
2. **2FA enabled**, verified via the API. Enrollment happens at home via the day-before pre-flight
   email, not live in the room. An attendee who arrives without it — an adopted account that never
   enrolled, or a fresh account signed up in the room — enrolls live as a **degraded fallback**:
   the pass criteria are unchanged, only the timing slipped.
3. **Recovery codes saved, and the owner states where.** Recovery codes only exist once 2FA is on,
   which is why enrollment comes first. **Claude never sees the codes.**

These are hard acceptance criteria for provisioning, not advice. Provisioning does not pass without
all three.

Related handling rules: tokens live in each official CLI's native credential store (`gh` → OS
credential store (Windows Credential Manager / macOS Keychain), `supabase` → keyring or its
fallback file `~/.supabase/access-token` where no keyring is available, `vercel` → its auth
file). Automation **detaches during credential entry** — a hands-off window with no DOM reads
while the owner types — and the driven browser profile is deleted after provisioning.

*Company extension:* a company may mandate SSO through its own identity provider or an enterprise
GitHub org. The rule that survives is *one chained identity, hardened, owned by the business* — the
2FA and recovery-code mandate becomes IT's to satisfy rather than the attendee's.

## 8. The apps are born under the owner's accounts. **[Individual]**

GitHub repo, Vercel project, Supabase project — all created under accounts the attendee owns, from
the first minute. Nothing is built under a Selr account and migrated later; a later migration
recreates exactly the "six places" pain this pack exists to remove.

*Company extension:* "the owner" becomes the company (org-owned repos, team-owned Vercel/Supabase).
The principle — the business owns its own infrastructure from day one, Selr never holds the keys —
is what carries over.

---

## What is off-path

Redirect, in plain English, rather than complying:

| Ask | Response |
|---|---|
| "Deploy to Netlify / Render / Cloudflare Pages instead" | One deploy target. Redirect here. `deploy-doctor` flags foreign hosts; it never operates on them. |
| "Keep it local for now" | Repo and Vercel link come first; local-only is the pain being solved. |
| "Just run the SQL in the dashboard" | Committed migrations only (convention 3). |
| "Use `vercel deploy` to push it up quickly" | Deploys happen by pushing to `main` (convention 3). |
| "Just deploy it straight from this folder" (a directory with no linked Vercel project) | Deploying from an unlinked directory silently creates a second Vercel project — a convention 1 violation on top of the CLI-deploy one (convention 3). Deploys happen by pushing the repo. |
| "Set up a second Vercel project on the same repo" (a test copy) | Never two Vercel projects on one repo (convention 1). |
| "Set up a staging branch" | Main-only in v1 (convention 2). |
| "Just put the API key in the code" / "commit the `.env`" | No secrets in the repo, ever (convention 5). |
| "Reuse my existing Supabase project for the second app" | One Supabase project per app (convention 6). |
| "Can Selr host it for me?" | Apps are born under the owner's accounts; Selr never holds the keys (convention 8). |

Every redirect opens with the fixed words **One blessed path** — then the row's response in the
owner's own plain English, naming this file so the owner knows where the rule lives. The opener is
deliberately fixed: it is the one phrase the trap-tests key on, leaving the rest of the sentence
free to be said naturally.

This table is the trap-test source. Guardrails are enforced as trap-tests in the nightly QA
autopilot (`qa/trap-tests/`): every row above is an adversarial fixture — a scripted owner puts the
ask in their own words, and the run passes only if the redirect comes back — and anti-pattern
matchers fail fast on any foreign deploy command. `vercel promote` used to undo a rollback stays
exempt (convention 4).

---

*Companion doc: `STACK.md` — what the stack is and why, including the platforms considered
and rejected. This file is only about how the blessed path is operated.*
