# Drift-check library

The pack's standing checks for the ways a deployed app quietly leaves the blessed path. This file
is canonical and `deploy-doctor` owns it: the doctor runs every check during its audit and applies
fixes behind click-to-change. **The contract for `app-status` is read-only** — it runs the
listing-safe detects, renders verdicts in its listing ("key mismatch — run deploy-doctor") and uses
DD-ACTIVITY for its pause countdown; it never applies a fix. Nothing here depends on that skill
being installed: the library is owned and run by the doctor either way.

The unit of every check is **one app**: `<owner>/<repo>` on GitHub, one Vercel project, one
Supabase project (`<ref>`), identified in the doctor's scope step.

## Rules

- **Detects observe; they never mutate.** Every detect is safe to run any time, from any state.
  All of them but one also run unattended, which is what a listing needs; the exception is
  DD-SCHEMA's `link`, which can pause for a password and is marked doctor-only where it appears.
  Scratch files a detect writes (an env pull, a shallow clone) land outside the app's working
  directory, are deleted after the comparison, and are checked gone — an env pull holds live
  secrets, so that deletion is reported, not assumed.
- **Detect from the world, never from a state file** (the registry rule, inherited from
  [checks.md](../foundation-check/checks.md)).
- **Every fix is doctor-only, per-item, on the owner's OK** (SKILL.md doctrine). Fix classes:
  `auto-on-OK` — Claude does it once the owner approves that item; `owner-in-loop` — Claude
  starts it, hands off during anything the owner must type; `owner-only` — link plus plain-English
  words, then re-detect. **Every dashboard step is `owner-only`** — this skill never drives a
  browser (SKILL.md), so a fix that only a signed-in dashboard can do is the owner's click, always.
- **An irreversible fix is re-confirmed by name before it runs**, whatever the owner said earlier.
  SKILL.md doctrine rule 2 defines what irreversible means and is the only authority on it; this
  file keeps no list of its own, it classifies each fix against that definition and says so in the
  cost column.
- **Any fix that pushes a migration runs the module's destructive protocol first.**
  [modules/data-auth/MODULE.md](../../modules/data-auth/MODULE.md) owns it and this file does not
  restate it: anything not provably additive is treated as destructive (convention 4), so the
  automatic Docker-free export of every affected table runs and the plain-English confirm names
  exactly what is lost — both **before** the push, because the push is what applies it. A migration
  the doctor did not write is read for destructive statements first, and if it has any, the same
  protocol applies. Export failed, or no confirm → no push.
- **Redeploys happen by pushing to `main`** — `git commit --allow-empty -m "redeploy"` then
  `git push` when there is nothing to change — run them as two separate commands.
  Never `vercel deploy` (convention 3).
- **Supabase CLI JSON is read with `-o json`, never `--output-format json`** — the long form wraps
  the payload in an envelope, and the rest of the pack (`supabase-provision` and its smoke tests)
  parses the bare form. This rule covers every `supabase` call in this file and in
  [strays.md](strays.md).
- **`vercel api` runs from PowerShell on Windows.** The subcommand (beta, real since CLI v56) takes
  a path starting with `/`; Git Bash rewrites that into a filesystem path and the call fails with
  "Invalid arguments". This rule covers every `vercel api` call in this file and in
  [strays.md](strays.md).

## The library — four checks and one datum

| ID | Answers | Fix class |
|---|---|---|
| DD-CD | Does a push to `main` still go live? | auto-on-OK, irreversible — every fix here changes what the domain serves; owner-only where only a dashboard can do it |
| DD-ENV | Do Vercel's env vars match the Supabase project's real URL and keys? | auto-on-OK; a leaked key is rotated owner-only, first |
| DD-PAUSE | Is the Supabase project awake? | owner-only |
| DD-SCHEMA | Does the applied schema match the committed migrations? | auto-on-OK, irreversible — export and confirm first |
| DD-ACTIVITY | When did this app last do anything? (datum, not a verdict) | — |

### DD-CD — continuous deploy is live

**Detect.** Compare `main`'s head with what the production **domain** is actually serving:

```sh
gh api repos/<owner>/<repo>/commits/main --jq .sha        # what main is
vercel api /v13/deployments/<production-domain>            # .meta.githubCommitSha = what the domain serves
vercel ls <project> --prod                                 # newest production build (for attribution)
```

(The deployments endpoint takes any host without `https://` — the production domain resolves
through its alias to the deployment actually behind it, which is the only honest "what is live";
a deployment URL resolves to that build. The newest production build is **not** the serving
deployment after a rollback, so `vercel ls` alone can false-pass. `vercel inspect`'s default output
prints status, aliases and builds but no commit SHA — verified on CLI 56.4.1; it also takes
`--format json`, whose payload this pack does not rely on.)

Drift when the serving deployment's SHA is not `main`'s head (a build still in flight is not
drift — re-check when it settles). Then attribute, in order:

1. **No git connection at all** — `vercel api /v9/projects/<project>` has no `link` to the repo.
   That API read is the detect; if the owner wants to see it for themselves, the dashboard shows it
   at project Settings → Git — no connected repository. CD was never wired, or the repo was
   disconnected.
2. **Rolled back with auto-deploy off** — the connection exists and the newest production build's
   SHA *is* `main`'s head while the serving deployment's is not: new pushes build but do not go
   live. The dashboard shows **Undo Rollback** — someone used convention 4's recovery button and
   the follow-through never happened.
3. **Deploy failed** — the newest production build is `main`'s head and errored (`vercel inspect`
   shows the error state); the domain still serves the last good deployment. Route the build error
   itself to `app-iterate` (it is a code problem, not drift).

**Fix.** Case 1 (auto-on-OK): from the app repo, `vercel git connect`. If it fails because the
Vercel GitHub app cannot see the repo, that half is **owner-only** — the owner widens repository
access to **All repositories** at github.com/settings/installations, the blessed scope from
`vercel-provision`, in their own browser; then re-run `vercel git connect`. Case 2 (auto-on-OK):
convention 4's follow-through, both halves — a fix or revert commit pushed to `main`, **and** the
rollback undone with `vercel promote`, sanctioned exactly here. Where `vercel promote` will not do
it, the **Undo Rollback** button is **owner-only**: give the words, the owner clicks. Either case
ends with a push and a fresh detect: production SHA = `main` SHA, URL 200 on a `HEAD` request.
Cost column: free — nothing is deleted and nothing is charged for. Both cases are **irreversible**
under doctrine rule 2 and re-confirmed by name immediately before they run: each ends in a push that
takes the production domain off what it serves now and onto `main`'s head, and case 2's
`vercel promote` moves the domain the same way. Say it to the owner in those words — the site's
content changes the moment this lands.

### DD-ENV — env/key drift

**Detect.** What the Supabase project really is, versus what Vercel tells the app:

```sh
supabase projects api-keys --project-ref <ref> -o json
vercel env pull <scratch>/.env.audit --environment=production --project <project>
```

That pulled file holds **every** production secret in plaintext, not just the two this check reads.
It lands in scratch, never in the app's working directory; it is deleted the moment the comparison
is done, checked gone, and reported in three states the way the provisioners report a driven kit
profile: deleted (with the path), deletion FAILED (with the path and what the owner must delete by
hand), or none written. `--project <name-or-id>` — verified on CLI 56.4.1, where it defaults to the
linked project — is what lets this run for an app with no clone on this machine; never run
`vercel env pull` from an unlinked directory.

Drift when `NEXT_PUBLIC_SUPABASE_URL` does not point at `<ref>.supabase.co`, when either variable is
missing from production env, or when `NEXT_PUBLIC_SUPABASE_ANON_KEY` is anything other than **this
project's current publishable key** — the `publishable` row of the api-keys output
(`sb_publishable_…`), or its legacy `anon` equivalent on an older project. A rotated, revoked or
another project's key is ordinary drift. A `service_role` or `sb_secret_…` value there is **not**
drift, it is a **leaked secret**: those are also rows in the same api-keys output, so "it's a valid
key" proves nothing. That value is public in every browser that has ever loaded the site and it
bypasses every RLS policy. Report it as its own finding, above the rest, and say plainly that
replacing the env var does not un-leak it. Also drift, one source violated (convention 5): a `.env`
committed to the repo — a secrets leak, called out as its own finding too.

**Fix (auto-on-OK).** `vercel env rm` / `vercel env add` the corrected values for production,
preview and development; `vercel env pull .env.local` locally; redeploy by empty-commit push.
Cost column: free and **reversible** — it deletes nothing, and its empty commit redeploys the commit
the domain is already serving rather than moving the domain onto a different one, which is the
distinction that makes DD-CD's push irreversible and this one not. The site is briefly rebuilding
while it does.

A leaked secret key — in the env var or in a committed `.env` — is not fixed by any of that. It is
rotated in the dashboard, by the owner (**owner-only**), **first**. The rotated secret key then goes
only where a server-side secret legitimately lives, and **never into any `NEXT_PUBLIC_` variable**.
The value written into `NEXT_PUBLIC_SUPABASE_ANON_KEY` is this project's current **publishable** key
(`sb_publishable_…`, or its legacy `anon` equivalent) — never the rotated secret, and never any
`service_role` or `sb_secret_…` value, whatever the rotation produced. A committed `.env` is
additionally deleted in a commit with its path added to `.gitignore`, and the report says the rest
out loud: deleting the file does not remove it from the repository's history, so every key that was
ever in it stays readable to anyone who has ever had access to that repo. The deletion is tidy-up;
the rotation is the fix.

### DD-PAUSE — Supabase project paused

**Detect.** `supabase projects list -o json` — the app's project by `<ref>`, status field. Drift
when the status is anything but active/healthy; the owner can see the same thing on their dashboard,
where the project tile says **Paused**. A paused project is the answer behind opaque 500s on an app
nobody touched for a week — free projects auto-pause after roughly one week idle (convention 6).

**Fix (owner-only).** The owner restores it: dashboard → the project → **Restore project**;
re-detect until active, then verify the live URL with a fresh `HEAD` request. Always said with the
restore, plain English: on the free tier it **will pause again** after another idle week — if the
business is actually using this app, this is the business-use trigger (convention 6): Supabase
Pro and Vercel Pro, named together, the owner's call. Cost column: **reversible** — restoring
deletes nothing and returns the project to the state it was already in, and the fix is owner-only
regardless, so nothing here runs unconfirmed either way. Restoring is free; the trigger this
conversation leads to is not, which is why it is named here and priced by convention 6.

### DD-SCHEMA — applied-vs-committed schema parity

**Detect.** The repo's `supabase/migrations/` versus what the database has actually applied:

```sh
# in a scratch shallow clone — `link` writes state under supabase/.temp/, which the app's
# working directory never absorbs (first rule above)
supabase link --project-ref <ref>      # owner-in-loop if it prompts for the db password
supabase migration list                 # local vs remote, side by side
```

This is the one detect in the pack that pauses for input, and SKILL.md's doctrine rule 1 carves it
out by name: it reads, and it writes nothing the app can see. The database password lives in the
owner's password manager (`app-builder` handed it over at create time). Claude keeps no copy —
it is typed or pasted for this one link and nothing in this skill writes it anywhere. What the
`supabase` CLI itself caches after a link is the CLI's own credential store's business, the same
store `supabase-provision` describes; the scratch clone the link ran in is deleted when the check
finishes.

No password to hand → fallback probe, weaker: check the newest committed migration's objects through
the REST API (`GET <url>/rest/v1/<table>?select=*&limit=1` with the publishable key —
`app-builder`'s verify pattern). The probe can see committed-not-applied; only the full list can see
the reverse. The link + list form is **doctor-only** — a detect that pauses for input is not
something a listing can run; the per-listing form of this check is the probe alone.

Both fixes end in a push to `main`, which is what applies schema — so both run the destructive
protocol in the rules above first, and both are **irreversible** in the report's cost column: a
migration that drops or narrows something is not undone by a rollback (convention 4).

That protocol has two entry conditions this check must meet before it can start, because the detect
above ran in a scratch shallow clone that is deleted when the check finishes and the app may have no
clone on this machine at all. First, the export runs from a **full working clone of the app repo** —
cloned first if there is none — never from the scratch clone, so the `exports/` directory it writes
is still there when the owner is asked to confirm and stays there afterwards; the owner is told the
path it landed at and that it is theirs to keep. Second, the export needs the project's secret key,
which the owner pastes from the Supabase dashboard for that one command — so that step is
**owner-in-loop**, and it is the second thing this check asks the owner for, alongside the database
password the detect may already have needed. If either condition cannot be met, or the export fails
for any other reason, the push does not happen.

Two drift states:

- **Committed, not applied** — migrations in the repo the database never ran. The GitHub-linked
  deploy is off, failed, or was wired after the push. Fix: the integration is confirmed in the
  dashboard by the **owner** (owner-only — Project Settings → Integrations → GitHub: connected repo,
  **Deploy to production** on `main`, per the module); then, auto-on-OK, trigger the apply with an
  empty-commit push and re-detect. These migrations have never run against this database and the
  doctor did not write them: read them for destructive statements before offering the fix, name in
  the finding exactly what applying them will change, and run the export first if any of it is not
  provably additive. Cost column: irreversible, and it names what applying the pending migrations
  changes about existing data.
- **Applied, not committed** — the database shows changes no migration file explains: dashboard
  SQL happened (convention 3 violation). Fix (auto-on-OK; the content is case-by-case): capture what
  production actually runs into a committed migration (written idempotent — `if not exists` guards —
  so the linked deploy can replay it safely), commit, push, re-detect. Capturing production's shape
  can put a `drop` or a type change into that file, and guards do not make those safe, so the same
  protocol applies: read what was captured, export, confirm, then push. The goal state is always:
  the repo shows what production runs. Cost column: irreversible.

### DD-ACTIVITY — last activity (datum)

Not a verdict — a timestamp the pack reads wherever idleness matters, most recently of:

```sh
gh api repos/<owner>/<repo>/commits/main --jq .commit.committer.date   # last push to main
vercel ls <project> --prod                                              # newest deployment's age
supabase migration list                                                 # newest applied migration — rides
                                                                        # DD-SCHEMA's link, doctor-only;
                                                                        # app-status reads the first two
```

Supabase exposes pause *status* but no inactivity timer (convention 6), and live API traffic —
which resets the real pause timer — is invisible to all three proxies, so the datum can
under-count activity on an app the business uses without pushing. That is why it is the anchor
for every idleness heuristic in the pack — `app-status`'s pre-emptive countdown ("your app
may sleep soon") is worded from it, **never as a precise countdown**. Inside this skill it feeds
DD-PAUSE's warning: an active free-tier project whose last activity is closing on a week gets the
pause warning before the pause, not after. It is also why this datum is read **before** any URL
check and why those checks are `HEAD` requests to a static route (SKILL.md run step 2): a full page
load on a pack app calls Supabase server-side, so an audit that browsed first would reset the timer
it is about to report on. No fix — activity is not a defect.
