---
name: deploy-doctor
description: Post-deploy doctor for the full-stack builder pack. Audits every app the owner has against the blessed path — continuous-deploy state, env/key drift, Supabase pause, applied-vs-committed schema parity — and hunts stray deploys (a second Vercel project on a repo, unlinked local-only dirs, foreign hosts). The audit is read-only; findings come back as a report with a per-item fix, and nothing changes without the owner's OK on that item. Use when an app that worked is now broken, after a workshop, when app-status flags drift, or any time the owner suspects their app lives in more than one place.
---

# deploy-doctor

The pain this pack exists to remove is an app deployed to **six different places with no continuous
deploy**. This skill is the cure applied after the fact: it finds every place an app actually lives,
proves whether the one blessed copy (`CONVENTIONS.md`) is healthy, and walks the owner — one
confirmed step at a time — back to exactly one repo, one Vercel project, one Supabase project,
push = deploy. It also owns the pack's **drift-check library** ([drift-checks.md](drift-checks.md)):
the standing checks for the ways a healthy app quietly stops being one.

## Doctrine — audit-first, click-to-change

Three rules bind every run:

1. **The audit is read-only.** Detects observe; they never mutate. No push, no env write, no
   Vercel project link or git connect, no deletion happens during the audit phase — the world is
   exactly as found until the findings report is on the screen. The one thing the audit asks of the
   owner is DD-SCHEMA's database password, in a throwaway clone: that link reads, writes nothing
   the app can see, and is the only detect in the pack that pauses for input. No password offered,
   no problem — DD-SCHEMA falls back to its weaker probe and the report says that it did.
2. **Click-to-change: every fix is applied per item, on that item's OK.** The report names what
   each fix will do in plain English — what it costs, what it deletes, what goes offline while it
   runs — before that fix runs; the owner approves items one at a time. **A fix is irreversible
   when it deletes data or a resource, or when it changes what the live site serves.** That
   definition is the pack's only one, and it — never the wording of a cost cell — is what classifies
   an item; everything else is reversible. A bulk "fix everything" answer covers only the reversible
   items. Every irreversible item is re-confirmed on its own, by name, immediately before it runs,
   whatever was said earlier; a further undo existing somewhere does not make it reversible.
   No confirm, no change.
3. **Never auto-delete — even confirmed, even in bulk:** anything currently serving traffic, any
   custom domain or DNS record, any database (Supabase project, or any other host's data store).
   For these the doctor's fix is **guidance only** — the exact plain-English steps, the owner's own
   hands in the owner's own dashboard. A production URL that returns 200 is presumed serving until
   the owner attests otherwise; a custom domain stays guidance-only even then.

## Before this skill

The audit reads through the authed CLIs — `gh`, `vercel`, `supabase`. Any of their auth checks
failing (`GH-AUTH`, `VC-AUTH`, `SB-AUTH` in [checks.md](../foundation-check/checks.md)) routes to
its provisioner first; the doctor never provisions. A missing *foreign* CLI is never installed —
foreign-host detection uses only what is already on the machine (strays.md).

## This skill never drives a browser

Every detect here reads through the authed CLIs, and every fix that needs a dashboard is
**owner-only**: the doctor gives the link and the plain-English words, and the owner clicks, in
their own browser, signed in as themselves. The doctor opens no browser — so there is no automation
profile to tear down and no credential window to hold, because nothing here is a sign-in. Where a
step genuinely needs a signed-in dashboard — widening the Vercel GitHub app's repository access,
Supabase's GitHub integration, **Undo Rollback** when `vercel promote` will not do it, restoring a
paused project — the fix class is `owner-only` and the report says so. Browsers get driven during
provisioning, under the provisioners' own "Consent and the credential window" contract
(`vercel-provision`, `supabase-provision`); this skill never provisions.

## Routing is honest

When a fix belongs to another skill, name the skill **and** say whether it is on this machine.
`app-iterate` owns every code or schema change; `app-status` renders this skill's checks read-only.
If the skill a finding routes to is not installed here yet, say so plainly, describe the change the
owner needs in plain English, and stop there — the doctor never improvises an app's code, and it
never quietly hands the owner a name that resolves to nothing.

## Run

**1. Scope.** Build the app inventory per [strays.md](strays.md): local app directories, the
owner's GitHub repos, Vercel projects, Supabase projects — four ledgers, cross-matched into apps —
closed by the owner interview ("any live URL you've ever shared that isn't on this list?").
The unit of everything after this step is **one app**: its repo, its Vercel project, its Supabase
project.

**2. Audit — read-only.** For each app, run the four checks and the DD-ACTIVITY datum in
[drift-checks.md](drift-checks.md); across the inventory, run the stray sweep in
[strays.md](strays.md). Collect verdicts and evidence; change nothing. Read DD-ACTIVITY **before**
any URL check, and make every URL check a `HEAD` request to a static route: a full page load on a
pack app calls Supabase server-side, which resets the idle timer the pause countdown is read from —
the audit would be faking its own evidence (convention 6).

**3. Findings report.** One table:

```
# | App | Finding | Evidence | Fix (on your OK) | Cost / what it takes with it
```

Ordered by the consolidation order below — blessed-path repairs first, stray offers last. The last
column is never empty: "free, reversible" is an answer, and so are "$25/mo plus usage", "deletes the
project permanently", and "the site is down for about a minute while it redeploys". That column is
where each item's cost is written and where its **reversible** / **irreversible** label is shown;
the label itself follows doctrine rule 2's definition, never the wording of the cell. Under the
table, one line, always: **"Nothing has been changed. Say the number to fix an item, or 'all' to
walk the reversible ones in order — I'll still stop and ask you again before anything
irreversible."**
A clean audit prints the table with zero findings and says so — that is a real result, not a wasted
run, and it says what it looked at, ledger bounds included (strays.md).

**4. Guided fix — consolidation order enforced.** Strays are consolidated only from a position of
strength:

1. **First, the blessed path is made live**: drift findings (CD off, rolled back, paused project,
   env drift, schema parity) are fixed — each on its OK — until the app's checks pass.
2. **Then the blessed URL is verified**: the production URL returns 200 to a `HEAD` request on a
   static route, freshly checked this run (step 2's rule — a full page load fakes activity).
3. **Only then, stray offers — one at a time**, per strays.md's decommission protocol: guided-fix
   for blessed-adjacent strays, FLAG-only for foreign hosts, and a **data-parity confirm before
   any decommission offer** — the blessed app holds the stray's data, or the owner states none
   exists.

Never point the owner away from a working stray toward a blessed path that isn't proven live yet.

**5. Re-check.** Re-detect every item that was fixed; print the final table. Fixed items show
their fresh passing evidence; declined items stay listed as findings — the owner's call is
recorded, not erased.

## Symptom triage — "my app broke"

When the owner arrives with a symptom instead of an audit ask, start at the likely cause, then run
the full audit anyway — drift travels in packs. Rows that end at `app-iterate` end there under the
routing rule above: name the change, say whether that skill is on this machine, and do not make the
change here.

| The owner says | Most likely | First move |
|---|---|---|
| "It worked at the workshop, now every page errors" — and it sat untouched about a week | Supabase auto-paused the project (the single most likely post-workshop failure) | DD-PAUSE |
| "I pushed a change and the live site didn't update" | Rolled back with auto-deploy off, or CD never wired | DD-CD |
| "The new feature errors — *relation does not exist*" | Migration committed but never applied | DD-SCHEMA |
| "*Invalid API key*" in the browser console, or every request 401s | Env/key drift between Supabase and Vercel | DD-ENV |
| "Pages load but every list is empty — no error" | Wrong keys reading the wrong project, else an RLS policy in the app's own schema | DD-ENV; clean → the fix is a code/schema change: `app-iterate` |
| "*Failed to fetch*" / CORS errors in the console | A paused project answers nothing, and a wrong Supabase URL answers from the wrong place — both read as CORS from the browser | DD-PAUSE, then DD-ENV; both clean → the app's own code: `app-iterate` |
| "The magic link never arrives" | Built-in mailer limits — org-member-only delivery, 2/hour (module doctrine, not drift) | `modules/data-auth/MODULE.md`; changes route to `app-iterate` |
| "My app is at two different URLs" / "I think I deployed it twice" | A stray | strays.md sweep |
| "The URL I shared is now a 404" | Domain changed, project renamed or deleted | Scope step's inventory, then DD-CD |

## The drift library is shared read-only

The contract with `app-status` is: it renders the drift-checks.md verdicts and the DD-ACTIVITY datum
(its pre-emptive pause countdown) in its listing — detects only, warnings worded as "run
deploy-doctor". Remediation lives here, behind click-to-change, and nowhere else. The doctor never
depends on that skill being installed: this library is owned here and runs here whatever else is on
the machine.

## Rules quoted from CONVENTIONS.md

- **Convention 1** — one repo per app; never two Vercel projects on one repo.
- **Convention 3** — push = deploy for code **and** schema; never `vercel deploy`; never deploy
  from an unlinked directory; schema changes only from committed migrations. Every fix in this
  skill that needs a redeploy gets one by pushing to `main` — an empty commit when there is
  nothing to change.
- **Convention 4** — the named drift state **rolled back with auto-deploy off** belongs to this
  skill's drift library; `vercel promote` used to undo a rollback is sanctioned. Its data half binds
  every schema fix here: rollback restores code, not data, anything not provably additive is
  destructive, and the pre-migration export and plain-English confirm run **before** the push that
  applies it — the module owns that protocol and drift-checks.md points at it.
- **Convention 5** — env vars live in Vercel, one source; key drift is a first-class check.
- **Convention 6** — free projects auto-pause after ~1 week idle; pause detection is a
  first-class check; the countdown warning is a heuristic, never precise.
- **What is off-path** — foreign hosts are flagged, never operated on.

## Not this skill

- Building a new app — `app-builder`. Changing a working app's code or schema — `app-iterate`
  (including every fix the triage table routes there).
- Listing apps and share help — `app-status`; it renders this skill's checks read-only.
- Pre-deploy machine readiness (accounts, CLIs, git identity) — `foundation-check` and the
  provisioners (`github-provision`, `vercel-provision`, `supabase-provision`), orchestrated by
  `app-foundation-setup`.
- CWK's `fullstack-debugger` — generic Next.js debugging with a foreign-host stack; pack apps
  route infra symptoms here and code fixes to `app-iterate`.
- CWK's `deploy-to-vercel` / `vercel-deployment` / `cloudflare-deployment` / `render-deployment` /
  `railway-deployment` — a stray or foreign-host finding is never "fixed" by deploying somewhere
  with another skill; the pack deploys only by pushing to `main` (convention 3).
- CWK's `supabase-admin` — database administration for the pack's apps stays inside the module's
  committed-migrations doctrine.
