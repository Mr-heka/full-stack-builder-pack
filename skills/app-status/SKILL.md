---
name: app-status
description: Read-only answer to "what apps do I have?", "how do I share it?", "is it still up?" — one table of every blessed-path app with repo, live URL (checked live, right now), last production deploy and days live, flagging any app whose page answers while the database behind it does not, plus the share helper that re-renders app-builder's next-steps card for any listed app. Drift warnings and the sleep countdown's per-app data are stubbed pending deploy-doctor's check library (M4). Use when an attendee asks any of those three questions. NOT for building a new app (app-builder), changing one (app-iterate), or fixing anything found here (deploy-doctor owns remediation).
---

# app-status

The read-only member of the M2 trio (`app-builder` builds, `app-iterate` changes, this skill
reports). It answers the three questions `app-builder`'s routing table sends here — *what apps do
I have? how do I share it? is it still up?* — with one table, and without changing anything in the
owner's GitHub, Vercel or Supabase accounts. The one thing it does spend is step 2's probe: one
page view per app, per run.

## Before this skill

Two auths plus the owner check, read-only all three: `gh` (GH-AUTH, **and GH-OWNER** — this table
says *your* apps, so the signed-in account has to be the owner's, not a colleague's and not a
shared laptop's leftover) and `vercel` (VC-AUTH), per the registry
([checks.md](../foundation-check/checks.md)). A failing GH-AUTH or VC-AUTH routes to its
provisioner; a failing GH-OWNER is owner-only — sign in as the owner (`gh auth login`, or `gh auth
switch` if that account is already on the machine), and only an owner with no account at all is
`github-provision`'s create path.
Nothing else is required — this skill is safe to run at any time, and Supabase auth is not needed
in v1 (the pause/last-activity feed is M4's).

## Steps

**1. Find the apps.** GitHub is the source of truth (convention 1) — discovery walks the owner's
repos, never local folders and never Vercel's project list.

```sh
gh api user -q .login                                            # the owner
gh repo list <owner> --json name,url,createdAt,pushedAt --limit 200
```

If that repo list comes back full at 200, say so rather than presenting a partial list as
complete. Vercel needs nothing read here: step 2's lookups carry no `--scope` flag and resolve on
whichever account the CLI is already pointed at. Do not try to pin one up front — `vercel whoami`
returns the signed-in *username*, and a personal account is refused as a scope outright ("You
cannot set your Personal Account as the scope"), so a guessed flag fails every call and the whole
table reads "couldn't check". What guards against answering from the wrong account is reading it
back off the lookup itself — step 2's `contextName` — and stating it with the table.

A repo is a blessed-path app when it carries the template's signature at its root: `app.config.ts`
**and** `CONVENTIONS.md` (the copy `app-builder` injects) — detect each with
`gh api repos/<owner>/<repo>/contents/<file>` (404 = absent). Both present = an app; anything else
is left alone. A local folder with no pushed repo is not an app (convention 1: not pushed = does
not exist) — `app-builder` finishes it. A Vercel project with no blessed repo behind it is a
stray, and strays are `deploy-doctor`'s (M4) — this discovery cannot see them at all, since it
never walks Vercel's project list.

**2. Fill each row.** Per app:

- **Live URL** — the Vercel project carries the repo's name: `app-builder` links it from a
  directory named after the repo (convention 1), so step 1's repo name *is* the project name.
  Its **READY production** deployments, newest first:

  ```sh
  vercel ls <repo-name> --environment production --status READY --limit 100 --format json
  ```

  One call serves two columns: the **first** row is the current production deployment, the **last**
  is the oldest one this app ever had. `--format json` is what makes those rows readable — both
  timestamps come from the payload's exact `createdAt` values, never from the human table's
  relative Age column, which rounds to "2mo" and would put Days live weeks out. Keep the list. The
  same payload also says whether it is the app's whole history: `pagination.next` is non-null only
  when older deployments exist past this page, and that — not a full-looking 100 rows, since 100 is
  also Vercel's per-page maximum — is what marks the Days live cell as a floor rather than
  presenting it as exact. And it names the account that answered, in `contextName` — read it, it is
  what step 3 states beneath the table. Always name the project, and never `cd` into an app folder
  and run a bare `vercel` command to work it out — a CLI command in an unlinked directory is how a
  second Vercel project gets created on an app that already has one (convention 3).

  The production domain comes from `vercel inspect <deployment-url>`'s aliases — never assume
  `<slug>.vercel.app` survived the global namespace. Then one request to that domain:

  ```sh
  curl -sS -L --max-time 10 -w '\n[status] %{http_code}\n' https://<domain>
  ```

  Follow the redirects and judge the **final** status — a domain that answers 308 on its way to
  200 is up, not broken. 200 = **Up**, meaning exactly *the page answers*.

- **What Up covers, and the half it doesn't.** Up on its own cannot clear the database: the
  template's home page stays up on purpose while a sleeping database fails behind it. But the page
  just fetched carries the template's own health list, so read it. Find the `Supabase connectivity`
  entry in that list and judge that entry's own mark: the label and its ✓/✗ plus detail are
  rendered as sibling elements, so markup sits between them and they are never adjacent in the
  served HTML — never string-match the two together, and filter the body down to that entry rather
  than dumping the whole page into the transcript.

  A ✗ on that entry is the other half of the cell, and the entry's detail decides the wording:

  - the connectivity attempt itself came back failing (an `HTTP <status>`, or `unreachable`) —
    **page up, database not answering**.
  - that entry failing for any other reason — **page up, health check failing**, and nothing
    beyond it: no detail text copied through, no naming which check or why, because those details
    are causes and the first wording would say something untrue of this app.

  Either way, report that and stop there: it is a signal, not a diagnosis. Which failure it is —
  paused project, key drift, wrong URL — is `deploy-doctor`'s call (M4), and both rows route there
  rather than naming a cause.

  Reading the body costs nothing extra. The home page is `force-dynamic` and makes its own
  Supabase auth-health request on every hit, so one probe spends exactly one organic page view
  whether the body is read or thrown away — the probe was never activity-neutral, and the
  genuinely activity-neutral read is still M4's management-API check.

- **Last deploy** — that newest READY production deployment's timestamp. Read from Vercel's
  deployments, never inferred from the last push — convention 3's "done" is *auto-deployed*, and
  this column tells the truth about it.
- **Days live** — days since the **oldest** READY production deployment (the last row of the list
  already in hand), which is when the app first became live — unless the payload's
  `pagination.next` is non-null, in which case older deployments exist past this page and the cell
  is marked a floor, not the day it went live. The repo's `createdAt` from step 1 is the fallback
  when there is no list, and a cell filled from it is marked approximate — repo age is not time
  live. On the blessed path the two are usually the same day, but not always: `app-builder`'s
  project-count gate can hold a build at the Supabase Pro decision for as long as the owner takes,
  leaving the repo and the Vercel link in place with nothing deployed.
- **"Came back empty" and "the lookup failed" are two different rows** — the table never merges
  them, because telling an owner their live app was never deployed is worse than telling them the
  check broke.
  - A clean run that returned no deployments: *"no production deployment — `app-builder`'s
    done-check never passed for this app"*, and it routes to `app-builder`.
  - A non-zero exit, an unknown project, a project the current account cannot see, a timeout,
    anything else: *"couldn't check"* plus the error the command actually printed, and it routes
    nowhere. A failed lookup is never rendered as an absent deployment. When the project turns out
    to live under a *team* the CLI is not currently on, that is the one case worth naming a scope
    for: `vercel teams ls`, then `vercel switch <team-slug>` or `--scope <team-slug>` — the team's
    slug, never the owner's own username, which the CLI refuses.

**3. Render the table.** Every column, every run:

| App | Repo | Live URL | Last deploy | Days live | Sleeping soon? | Drift |
|---|---|---|---|---|---|---|
| jones-plumbing-jobs | github.com/… | jones-plumbing-jobs.vercel.app — **Up** | 3 days ago | 12 | — | — |
| dee-why-bookings | github.com/… | dee-why-bookings.vercel.app — **page up, database not answering** — run deploy-doctor | 9 days ago | 9 | — | — |
| mila-cakes | github.com/… | mila-cakes.vercel.app — **page up, health check failing** — run deploy-doctor | 2 days ago | 30+ (floor — older deploys past this page) | — | — |
| tanner-quotes | github.com/… | couldn't check — `vercel ls` said the project was not found in this scope | couldn't check | 4 (approx — repo age) | — | — |

**The two stub columns and the note that must accompany them:** *Sleeping soon?* (the pre-emptive
sleep warning — "your app sleeps in ~2 days", always approximate) and *Drift* ("key mismatch —
run deploy-doctor") render `deploy-doctor`'s check library — Supabase pause status,
last-activity, env/key/CD drift — which is owned by `deploy-doctor`; the feed into this table
is not wired yet.
Until it is, both columns show "—" plus this note: **rendered read-only when live, remediation
doctor-only, and nothing guessed meanwhile** — no per-app sleep estimate gets invented from a
heuristic here.

Beneath the table, three standing lines:

- **The account the deploys were read from, every run:** the `contextName` step 2 read out of the
  lookup payload — *"deploy data read from `<contextName>`"*. Stated whether or not it looks right,
  because it is the one thing that makes a table built from the wrong Vercel account visible to the
  owner rather than silent. If the lookups answered from more than one account, name each; if every
  lookup failed there is none to name, and the table says so.
- **The sleep warning, every run:** on the free database plan an app nobody uses for about a week
  goes to sleep — its real pages then show errors — until the owner wakes it with the one-click
  Restore on their next-steps card (step 4 re-renders the card if it's lost). Said every run even
  when every row reads **Up**, because the Live URL cell only catches this once it has already
  happened: the warning is the pre-emptive half, and it is the single most likely "my app broke"
  event.
- **Any URL not answering 200 after redirects:** report what was seen, plainly ("answered 404 —
  the deploy itself is broken", "no answer within 10s"). That is the page failing, which is a
  different thing from the page answering while its own health list does not come back clean —
  those two are already in the Live URL cell as *page up, database not answering* and *page up,
  health check failing*.

**Before this goes on a shared screen:** the table is the owner's own inventory — their GitHub
login, their private repos, their live URLs. Say so before rendering it in a room, and never paste
a rendered table into a support thread without the owner's OK.

**4. Share help.** "How do I share it?" = re-render `app-builder`'s next-steps card for that
app — its step 7, `next-steps.mjs`, all slots, run from the pack install path exactly as
`app-builder` documents it. Three inputs come from here. `--url` is step 2's resolved production
domain for that app — the same domain the Live URL cell was probed against, and the script exits
with a usage error on anything that is not a bare https URL, so a row with no URL never reaches
it: *"no production deployment"* means there is nothing to share yet and routes to `app-builder`,
and *"couldn't check"* means the lookup failed, not that the app is unshareable — say so and re-run
step 2 for it. `--name` is `businessName` read from the repo's `app.config.ts` (`gh api
repos/<owner>/<repo>/contents/app.config.ts`, base64-decoded — no local checkout needed), and
decoding it goes only as far as reading that one value: the same file holds `ownerEmail`, which has
no business being echoed into a transcript or onto a shared screen.
`--business-use` is the mini-plan's intended-use answer — ask the owner if it isn't known, since
it picks the cost line. The blurb's audience is family and friends; business promotion waits for
Pro (`STACK.md`).

## Rules quoted from CONVENTIONS.md

- **Convention 1** — the repo is what exists; a working directory is a cache of it. Discovery
  therefore walks GitHub, and unpushed work is not an app.
- **Convention 3** — deploys happen only by pushing, which is why "last deploy" comes from
  Vercel's deployments: "done" means *auto-deployed*, not *pushed*.
- **Convention 6, cliff 2** — free projects auto-pause after ~a week idle; `app-status` warns
  pre-emptively and approximately — pause status + a heuristic once M4 feeds it, never a precise
  countdown. The day-30 sweep's still-alive rule — a static route / HEAD request plus a
  management-API status check, because a DB-touching ping resets the idle timer and fakes its
  own evidence, and a page probe alone cannot see a paused database — is quoted for the sweep,
  not satisfied by step 2's probe: the home page is not a static route. What step 2 *can* do is
  read the template's own health list out of the page it already fetched. That is a signal about
  one app, not the activity-neutral status check the sweep requires.

## Not this skill

- A new app — `app-builder`; changes to a listed one — `app-iterate`.
- Every fix this table surfaces — a database not answering, drift, waking a paused project —
  belongs to `deploy-doctor` (M4): audit-first, click-to-change, and it is also where the strays
  this table cannot see get found. This skill reports what it saw and names no causes.
- Accounts, CLIs, SSO — `github-provision` / `vercel-provision` / `supabase-provision`;
  pre-flight verdicts — `foundation-check`.
