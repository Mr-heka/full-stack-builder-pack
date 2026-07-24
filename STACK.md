# STACK.md — the platforms this pack builds on

> **Locked (2026-07-20).** Source of truth for the
> decisions below: `.claude/documents/full-stack-builder-pack-plan.md` (rnd-vault), M1 grilled
> 2026-07-13, hardened through seven adversarial review rounds (Codex APPROVED, round 7).

## The short version

Every app this pack builds runs on the same four platforms:

| Platform | What it does | Who owns it |
|---|---|---|
| **GitHub** | Holds the code. The record of what the app is. | The attendee |
| **Vercel** | Runs the website. Every push to GitHub goes live automatically (paused only while a rollback is in force). | The attendee |
| **Supabase** | Holds the data — bookings, jobs, leads, customers. | The attendee |
| **Next.js (App Router)** | The framework the app is written in. Claude writes it; the attendee never touches it. | n/a — it's code |

One decision underneath all four: **the attendee signs in once with GitHub, and that same login
creates their Vercel and Supabase accounts.** Three platforms, one account to remember, one thing
to protect. That is what makes a thirty-minute setup realistic.

And one rule that makes the whole pack cohere: **push = deploy.** When Claude pushes code to
GitHub, Vercel rebuilds the site and Supabase applies any database changes. There is no separate
"now upload it" step, because that step is where people lose their apps.

## Why these four

### GitHub — because the code has to live somewhere the attendee owns

The failure we are solving is an app that exists only on one laptop. GitHub is where the app stops
being a file on a hard drive and becomes a thing with a history, a backup, and an address. It is
also the identity anchor: Vercel and Supabase both accept "sign in with GitHub," so setting up
GitHub properly sets up everything.

That concentration is deliberate, and it is the one real risk we take. If an attendee loses their
GitHub account they lose access to all three platforms at once. We accept it because one account to
protect beats three accounts to forget, and we mitigate it hard: business email the owner controls,
two-factor authentication switched on before the workshop (enrolled live in the room only as a
degraded fallback — convention 7 in `CONVENTIONS.md`), recovery codes saved somewhere the owner
can name out loud. Claude never sees any of it.

### Vercel — because deploying is meant to be invisible

Vercel is owned by the same people who make Next.js, so the app deploys with no configuration at
all. Connect the repo once and every push is live in under a minute. When something breaks, the
undo is one click — Vercel rolls back to the previous version on demand (reaching anything older
than that is a paid-tier feature). A rollback is a stopgap, not a resting state: while it is in
force, new pushes build but do not go live, so the follow-through — fix, push, undo the rollback —
is convention 4 in `CONVENTIONS.md`. For a non-technical owner who just changed something and broke
their booking form, that button is the difference between a bad afternoon and a bad month.

### Supabase — because a real business app needs a real database

Most small-business apps are a database with a nice front on it: jobs, bookings, quotes, leads.
Supabase gives us a proper Postgres database plus logins, file storage, and an API, without anyone
having to run a server. Critically, it connects to GitHub the same way Vercel does: database changes
are written as files, committed alongside the code, and applied when the code is pushed. The
database can't silently drift away from the app: both come from the same push, and `deploy-doctor`'s
standing parity check catches the one case a push can't rule out — code deployed, migration failed.

### Next.js App Router — because Claude writes best in it

This one is not an attendee-facing decision at all. Attendees describe what they want in plain
English; Claude writes the code. So the question is not "which framework is easiest for a beginner"
— it is "which framework does Claude write most reliably." That is Next.js with the App Router: the
most training coverage, the most examples, the fewest surprises. It is also Vercel's native
framework, so nothing needs adapting, and it is the current direction of the project, so nobody
hits a rewrite wall in twelve months.

Simplicity, in this pack, is delivered by the template and the skills — not by picking a smaller
framework.

## Why not the alternatives

**Cloudflare.** Technically capable and genuinely cheap, but running Next.js there needs an adapter
layer that occasionally disagrees with the framework, and the whole product is pitched at
infrastructure engineers. Every extra concept is a place a non-technical owner gets stuck. We are
in the business of removing nuance, not adding a well-priced pile of it.

**Render.** A solid host, but it wants you to think about services, instances, and build commands.
Vercel wants you to connect a repo. For this audience that difference is the entire product.

**Netlify.** Nothing wrong with it — and that is exactly the problem. Netlify is a second good
answer to a question we have already answered. A second deploy target is how you get the pain
The problem this solves: apps scattered across six places, nobody sure which one is live. One blessed path,
no exceptions. Netlify is something our deploy-doctor flags, not something our skills offer.

**Local-only.** The default failure. The app works beautifully on the laptop it was built on, nobody
else ever sees it, and it quietly dies. This is the pain that justifies the pack. The pack enforces
against it structurally rather than by advice: the repo and the deploy connection are created
*before* any code is written, and an app is only "done" when a pushed commit has gone live, the URL
answers, and any schema change actually applied — the full check is convention 3 in `CONVENTIONS.md`.

**Lovable, Bolt, v0, Replit.** These are the tools attendees will name, and they deserve a straight
answer: they are genuinely good, and they are the wrong shape for a business asset.

They are rented platforms. The app lives inside someone else's product, iteration is metered by
credits, and the owner does not really hold their own code — so when the tool changes its pricing,
its model, or its mind, the business's booking system is downstream of that decision. Our attendees
walk out owning a GitHub repo they control, on infrastructure they can hand to any developer alive.

We should concede the point where it is true: for a throwaway prototype, a mockup for a meeting, or
seeing an idea on screen in ten minutes, those tools are excellent and we are not competing with
them. The moment the thing has to survive — take real bookings, hold real customer data, still work
next year — it needs to be code the business owns.

## The Vercel tier question

**Workshop builds start on Vercel's free Hobby plan. Any app the business will actually use moves to
Pro ($20/month) before that happens.** One click, same account, no migration.

The honest part, which we should not bury:

Vercel's fair-use rules treat **paid help** creating or hosting a site as commercial use. A paid
workshop is paid help. That means the workshop's own deploys sit closer to the commercial line than
a plain reading of "it's just a personal project" suggests — regardless of whether the app has any
customers yet.

Our stance, deliberately chosen:

- **The Hobby window is short and it is an evaluation.** Days, not months. It exists so the attendee
  gets the moment where their app is live before they have entered a card.
- **Personal audience only during that window.** Show it to family and friends. No customer traffic,
  no link from the business website, no promotion. The share wording in the pack says exactly this.
- **Pro before any business use, enforced in the tooling.** `app-builder` asks what the app is for
  during its mini-plan. If the answer is business use, the attendee hits an explicit
  evaluation-vs-Pro gate that names both upgrades — Vercel Pro ($20/month) and Supabase Pro
  ($25/month plus usage-based compute, which we never quote as a flat number). The trigger rule and
  its rationale are stated once, as the business-use trigger in convention 6 of `CONVENTIONS.md`.
  The next-steps template recommends Pro by default for anything business-facing.

Two alternatives were weighed and rejected:

- **Selr hosts workshop apps on our own Pro team.** Rejected. Apps must be born under the attendee's
  own accounts — that is the doctrine the whole pack rests on — and moving them off our team later
  recreates the exact "six places" mess we exist to prevent.
- **Owner pays before the first deploy.** Rejected. Making someone enter a credit card before they
  have ever seen their app live kills the single best moment in the workshop.

So the current position is a deliberately accepted risk over a short, personal-audience window, with
the upgrade gate doing the real enforcement. It is not a technical problem with a technical fix.

**Signed off (deep-dive agenda #2):** the short personal-audience evaluation window stands as
written above. Who pays the platform fees once apps go to Pro — bundled into a higher ticket price,
a premium tier, or owner-paid at the point of upgrade — remains a business decision; the cost
lines land in the instructor runbook (M5) once packaging is decided.

## What this means for the pack

Every skill in this pack assumes this stack and nothing else. `app-builder` creates a GitHub repo and
a Vercel link before writing a line of code. `app-iterate` changes an app by pushing to main.
`deploy-doctor` treats anything outside this path as drift to be flagged. When an attendee asks for
Netlify, or asks to keep it local for now, the skills redirect them here — and we test that they do.

The rules for how the path is walked — one repo per app, main is production, environments live in
Vercel, migrations are always committed — are in `CONVENTIONS.md`.
