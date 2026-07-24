---
name: app-iterate
description: Changes an app that already exists — plain English in ("add a notes box to each job"), the change live at the same URL out. Nothing is built until the owner says yes to a push that replaces their live site. Pull first (the repo is the truth; a project asleep on the free tier gets woken before anything else), edit, safe migration per the data-auth module — anything destructive gets an automatic pre-migration export plus a plain-English confirm naming what's lost, both BEFORE the push — then one git push that deploys code and schema, then verify (commit auto-deployed, URL 200, migration actually applied). Recovery is Vercel one-click rollback for code, Claude-assisted restore from the export for data. Customer sign-in stays owner-only in v1 — it sets up custom email, never customer accounts. Use when an attendee asks to change, add to, or fix an app the pack already built. NOT for building a new app (app-builder) or listing/sharing apps (app-status).
---

# app-iterate

Changes one existing app on the blessed path (`CONVENTIONS.md`). This skill exists to kill the
"80% in the first prompts, then stuck" wall: every change after build day — new field, new page,
new table, a fix — is one plain-English ask away, and it rides exactly the same path the build
did. Pull → edit → safe migration → push = deploy → verify. No second way in through the
dashboard, no quick CLI deploy, no schema change that isn't a committed migration.

## Routing — the M2 trio

| The attendee says | Skill |
|---|---|
| "Build me an app that…" — an app that doesn't exist yet | `app-builder` |
| "Change / add / fix …" on an app that already exists | **this skill** |
| "What apps do I have?" / "how do I share it?" / "is it still up?" | `app-status` |

Three skills, no modes. An app "already exists" once `app-builder`'s done-check passed; a change
ask arriving mid-build belongs to `app-builder` until then.

## Scope

The v1 In/Refused lists live in `app-builder`'s SKILL.md and bind every iterate ask the same way —
a payments, native-mobile, multi-tenant or real-time ask gets the same plain-English redirect
whether it arrives on build day or three weeks later. Two gates are this skill's own:

### The business-use gate — named here, because build day may have missed it

`app-builder`'s mini-plan asks whether the app is for evaluation or for business and gates the
free tier on the answer. An app built for evaluation crosses that line **later** — and later is
here. Convention 6's business-use trigger fires on the first app the business actually *uses or
promotes*: linked from the business website, handed to a customer, real customer records going
in, or the ask that always signals it — the app needing reliable email of its own.

When a change crosses that line, name both upgrades together, once, **before** the work starts
and never after it: **Vercel Pro ($20/mo)** and **Supabase Pro ($25/mo plus usage-based
compute — never quoted as a flat $25)**. The choice is the owner's, and it is the same two
options `app-builder`'s gate offers: **(a)** not business use yet — it stays on the free tier
as a personal-audience evaluation, days not months, upgrade before any customer traffic, and
the Pro-by-default line is still said at the close; or **(b)** upgrade now, walked through in
the Vercel and Supabase dashboards **before** this visit's work starts, not alongside it.

This skill renders no next-steps card and writes to no registry, so the answer is recorded the
only way it can be: said back to the owner in the moment ("so we're staying free for now, and
I'll flag it again when customers are actually using this") and carried into step 6's close.
Never walk past the question because build day already asked it — an evaluation-built app is
meeting it here for the first time, and the cost is meant to be said once, before the app is
real, not discovered in a bill.

### Customer sign-in — owner-only in v1, and this skill says so

Every app the pack builds signs in exactly one person: the owner. **"Can my customers log in
too?" is not something this skill delivers**, and that is said plainly at the moment it is
asked rather than deferred into a step that never comes. Two separate reasons, both honest:

- Supabase's built-in mailer only delivers auth emails to the project organisation's own
  members, at 2 emails per hour — a customer's magic link would **silently never arrive**.
  Custom SMTP fixes that half.
- The half custom SMTP does **not** fix: the template's `files` bucket admits **any**
  authenticated user (`modules/data-auth/MODULE.md`, storage). Letting strangers create their
  own accounts before per-user storage policies exist would hand them the owner's files. Those
  policies are a new committed migration and a reviewed piece of work — not something to
  improvise on a live business app during a change request.

Say it like this:

> Right now sign-in emails can only reach **you** — the free built-in mailer won't deliver to
> anyone else, so a customer's sign-in link would simply never arrive. I can give the app its
> own email sender today (a service like Resend or Postmark, wired into Supabase), which makes
> your own sign-in reliable and is the first thing customer accounts would ever need. Customer
> accounts themselves are a separate build — I'm not going to half-open the app and leave your
> files reachable. It stays yours-only until that's done properly. Want the email sender set
> up today?

**What this skill will do — custom SMTP, and stop there.** The business-use gate above fires
first; then, in the module's order (`modules/data-auth/MODULE.md` holds the canonical form):
configure custom SMTP in Supabase Auth settings → confirm the owner's own first sign-in already
happened → disable project-level signups (Auth → "Allow new users to sign up"; mandatory
companion, not optional hardening — once mail leaves the organisation, the public OTP endpoint
would otherwise let a stranger sign themselves into exactly the class the `files` bucket
admits). Then re-run the owner smoke test *after* the switch — step 5 says why that is not
optional.

A custom-SMTP-only ask does not travel the Steps' commit path. It changes no code, adds no
migration and leaves nothing to commit, so **steps 3 and 5 do not apply to it**: there is no
`npm run build` to go green, no push, and **no deployment to poll for** — polling for one would
report broken continuous deployment on a perfectly healthy app, and an empty commit invented to
give the poll something to find is never sanctioned. Its consent is step 2's dashboard-only
branch, and its acceptance is the one check that does carry over: the owner smoke test re-run
after the switch (step 5's last check says why).

That dashboard work carries the provisioners' contract unchanged, never restated here in
weaker words: either talk the owner through it in their own browser, or drive it — and a driven
browser runs on its own throwaway profile, never the owner's; hands off entirely while they
sign in; and on end, pass or fail, the profile is deleted and reported in the three states
`supabase-provision` defines (its "Consent and the credential window" section). The mail
provider's API key is the owner's to paste, exactly as their password is.

**What this skill will not do**, on this visit or any other in v1: widen the `isOwnerEmail`
predicate in the template's `lib/owner.ts`, re-enable project-level signups, or add the
per-user storage policies customer accounts require. Those three land together or not at all.
Never leave the owner believing customers can now sign in: with signups disabled a customer has
no account and Supabase will not create one, so a widened predicate would admit nobody and the
failure would reach them as an error message they cannot read.

## Before this skill

The app passed `app-builder`'s done-check: repo on GitHub, Vercel project linked with push =
deploy live, Supabase project wired with the GitHub migration deploy, owner sign-in working.
Foundation (accounts, CLIs) is assumed green — an auth failure mid-run routes to its
provisioner, not to improvised re-auth here.

## Steps

**1. Pull — the repo is the truth, the working directory is a cache.** Before touching anything:

- Name the app back before touching it — the slug **and** the live URL it deploys to. That URL
  comes from the same place step 5's live-URL check reads it — the Vercel project's **Domains**
  settings — and is never assumed to be `<slug>.vercel.app`, because an app on a custom domain
  would otherwise have step 2 quoting the owner an address their customers don't use. The owner
  may hold more than one app (convention 6's free-tier cap is about two), and "add a notes box
  to each job" fits two job trackers equally well. Two candidates → ask which one. Never
  guess: the wrong app named here is the wrong app changed, and where this visit does push,
  that is what goes live.
- Find the app under the apps base directory (`~/apps/<app-slug>`). Not on this machine →
  `gh repo clone <owner>/<app-slug> ~/apps/<app-slug>` — cloning **is** the normal path on a
  second machine, not a recovery move.
- Confirm it is a pack-built app before changing anything: the repo carries `app.config.ts`,
  the injected `CONVENTIONS.md`, and `supabase/migrations/`. Any of them missing → **stop**.
  That is not an app this skill built and its deploy path is unknown — pushing to its `main`
  either deploys something this skill cannot verify or silently deploys nothing while step 5
  reports failures the owner can't act on. Apps built outside the pack are `deploy-doctor`'s to
  look at, never this skill's to change.
- A fresh clone isn't workable yet — `node_modules` and the `.vercel/` link are both
  git-ignored. `npm install`, then re-link to the **existing** Vercel project: confirm it's
  there first (`vercel projects ls` lists one named for the app), then
  `vercel link --yes --project <app-slug>` to exactly that project. No matching project →
  **stop** — the link step must never create one (a second Vercel project on the repo is the
  convention-1 violation), and a repo whose project has gone missing is `deploy-doctor` drift.
- Uncommitted local changes in the tree → stop and show the owner what's there before anything
  proceeds. Never discard or stash silently.
- `git pull` on `main`. Another session, another laptop, or a rollback follow-through may have
  pushed since this directory last saw the repo.
- `.env.local` missing → `vercel env pull .env.local` (convention 5 — envs live in Vercel).
- **Is the site currently rolled back?** Check before building, not after pushing. Start with
  the signal that costs nothing and needs no browser: after the pull, read what SHA production
  is serving (the same `vercel inspect` read step 5 uses) and compare it to the tip of `main`.
  Production sitting on an older commit only means anything **once the build has settled**: a
  newer deployment still building is a push in flight — someone else's, exactly as the bullet
  above anticipates — not a rollback. Wait for it the way step 5 waits, a few minutes, and look
  again. An older production commit with no build still running is the rollback fingerprint, and
  confirming it means looking where the state is actually visible — the Vercel dashboard →
  **Deployments**, where a rolled-back project shows the older deployment serving production and
  offers **Undo Rollback**. That is the owner's own dashboard and one glance
  answers it, so the default is to ask them to look and say what they see. Driving a browser
  instead is allowed, and carries the provisioners' contract unchanged and by reference, never
  restated here in weaker words: throwaway profile, never the owner's; hands off entirely while
  they sign in; profile deleted on end, pass or fail, and reported in the three states
  `supabase-provision`'s "Consent and the credential window" section defines.

  In that state new pushes build but never go live (convention 4's drift state *rolled back with
  auto-deploy off*), so this visit's change would be invisible and step 2's "it goes straight
  onto your live site" would be untrue. Establish **why** it was rolled back and whether the
  change that broke the site was ever fixed or reverted, before anything is agreed or edited.
  Three outcomes, each with an action:

  - **Rolled back, and the change that broke it was already fixed or reverted** — only the undo
    half was ever missed, which is exactly the drift this skill clears (*Not this skill*, last
    section). Step 1 finds it and **says it**; it does not press the button first. Undoing the
    rollback promotes the tip of `main` to the live site, so it changes what the public sees and
    takes its own plain **yes**, in the same shape step 2 uses:

    > Your site is showing an older version right now — that's the rollback from before. The
    > code has been fixed since, so undoing the rollback would put the current version live at
    > `<production URL>`, replacing what you're looking at now. Want me to do that?

    Yes → **Undo Rollback** in that same Deployments view (or `vercel promote`), confirm
    production is serving the tip of `main` again, say so, and carry on with today's change on a
    site that will actually receive it. **No is a complete answer** — an owner who rolled back
    deliberately may want to stay on the older version until they have looked at the fix
    themselves, and that is theirs to choose. Leave it alone, say back that the site stays as
    they see it and that pushes will keep building without going live until it is undone, and
    either carry on under step 2's rolled-back consent sentence or — if the change they asked
    for only makes sense on a site that is current — say that plainly and stop there.
  - **Rolled back, and the breaking change is still on `main` — or nobody can say why** — stop
    and settle that first, before anything new is agreed or built. Say it plainly ("your site is
    serving an older version right now, and the change that broke it is still in the repo"),
    because **Undo Rollback promotes whatever is on `main` now** — today's change stacked on top
    of the broken commits included.
  - **No rollback in play** — carry on. Production serving an older commit with no rollback
    behind it is broken continuous deployment, which is `deploy-doctor`'s, not this bullet's.
- The database has to be **awake** before anything is pushed. Probe the project's REST root
  (`GET <SUPABASE_URL>/rest/v1/` with the publishable key from `.env.local`). Free Supabase
  projects auto-pause after roughly a week of inactivity (convention 6), and this skill's
  visits are usually weeks apart — a paused project is the most likely thing to be wrong on
  arrival, and it answers with opaque 500s rather than saying so. Read the answer, don't
  flatten it:
  - A **200** is awake. Carry on.
  - A **401 or 403** is not a pause — it is key drift, and the keys came from Vercel, so it is
    a convention-5 env/key problem and a `deploy-doctor` check. Route it there. Never send this
    owner to the dashboard to resume a project that is already running.
  - A **5xx or a connection failure**, with the keys otherwise known good, is the pause signal.
    Pause *status* is not visible at the REST level — confirm it where convention 6 says it
    lives, the management API status check or the project's Supabase dashboard, before telling
    the owner anything. Confirmed paused → resume it there and wait for it to come up before
    step 2.

  A migration pushed at a paused project has nothing to apply to, and every probe in step 5
  then comes back looking like a failure that isn't one. (Touching the database here is right —
  this visit is about to change it anyway. The don't-touch rule belongs to the day-30 still-live
  sweep, which must not reset the idle timer.)

**2. Say the change back — and get a yes before any of it starts.** One or two sentences in the
attendee's own words: what will change, and whether the database is touched
("this adds a *notes* box to each job — that's a new column in **jobs**"). A refused ask gets
its redirect here, not after work has started, and a change that crosses into business use
trips the gate in *Scope* above — both upgrades named here, before building, never after.

Then say what happens when it's built — in the same breath, every time. Work that changes the
app's **code or schema** gets the goes-live sentence:

> When I push this it goes straight onto your live site at `<production URL>` — the same
> address your customers use — and replaces what's there now.

**If the owner declined the undo at step 1**, that sentence is untrue and gets replaced, never
just skipped. **Anything touching the database waits**: the migration applies on push while the
site keeps serving older code, and those two out of step is how a working app starts erroring in
front of real visitors. Say that, and offer the way forward — undo the rollback now, then this
goes on top of the current version. **Code-only work** may go ahead if they want it now:

> I'll save this and build it, but your site keeps showing the version you chose to stay on —
> it won't go live until you want the rollback undone, and that's one click whenever you're
> ready.

**Dashboard-only work** — the custom-SMTP switch is the one this skill does — pushes nothing,
so the goes-live sentence would have the owner agreeing to a deploy that never happens. Say
what actually changes instead:

> This one doesn't change the app itself — it changes a setting in your Supabase project so
> sign-in emails go out through your own sender instead of the free built-in one. Nothing gets
> pushed, and your live site stays exactly as it is.

In every case, wait for a plain **yes** before any of it starts. This holds for **every** change,
additive schema included: "applies silently" in step 4 describes the database, never the owner.
No yes, no work — a change the owner hasn't agreed to isn't a small change, it's an unrequested
deploy of their business's live site. Then build exactly that, nothing more.

**3. Edit.** Code changes per the template's existing patterns; anything database-shaped follows
the module: schema changes are **only** a new migration file
`supabase/migrations/<YYYYMMDDHHmmss>_<slug>.sql` (UTC timestamp), committed with the code that
uses it — never dashboard SQL, never a CLI apply. `npm run build` must be green locally before
anything is pushed.

**`/up` survives every visit.** The template's liveness route (`app/up/page.tsx`) belongs to no
feature and is never this visit's to delete, move or rename, and never gets wired to anything read
at request time — no Supabase client, no cookies, headers or `searchParams`, no call to the app's
own API. It stays excluded from `proxy.ts`'s matcher too: a matcher widened back over `/up` — by a
tightened auth rule, or by a reorganised `app/` that nobody re-checked — puts the auth proxy on
that path, and the proxy constructs a Supabase client on every request to it. The reason is a
promise already made out loud: at handover the owner was told the day-30 check-in **neither reads
your data nor wakes the database**, and that one static route is the whole of what makes it true. A
`/up` that is gone or dynamic doesn't fail loudly — it makes the promise false weeks later, on a
sweep nobody is watching, and quietly resets the idle timer it exists to avoid (convention 6).

So a visit that touches anything under `app/` or touches `proxy.ts` reads the route table
`npm run build` prints, **before** the push, and confirms `/up` is still listed with the static
marker `○`. A `ƒ` beside it, or no `/up` in the table at all, means this change isn't finished —
fix it here, where it costs one edit, not after it is live. On the rare ask that genuinely can't
live alongside a static `/up`, don't improvise around it: say what it would cost the owner in the
same plain terms the card used, and let them choose.

**4. Migration safety — before the push, because the push is what applies it.** From the module,
in this order:

- **Additive** (new tables, new nullable columns, new policies) → applies silently. Commit and
  move on. "Silently" is about the database, not the owner: they already said yes at step 2,
  and no schema change of any shape reaches `main` without that. **Anything not provably
  additive is destructive** — drops, renames, type narrowing, row deletes, and index builds on
  populated tables all count.
- **Destructive** → two steps, both before the push, export first (it supplies the row counts
  the confirm names):

  1. Automatic Docker-free export of every affected table:

     ```sh
     # run from the app repo — the script reads the project URL from .env.local there
     SUPABASE_SECRET_KEY=sb_secret_... node ~/.claude/skills/full-stack-builder-pack/modules/data-auth/scripts/export-tables.mjs <tables...>
     ```

     Writes `exports/<timestamp>_pre-migration/<table>.csv` + `.sql` (git-ignored). The owner
     supplies the secret key for that one command — never committed, never written to the repo
     or `.env.local` (the script ignores it there on purpose), and not one of the app's Vercel
     env vars. **Export fails → the migration does not get pushed.**
  2. Plain-English confirm naming exactly what's lost — the table, the column, the row count
     from the export, and what the business loses ("all **214** saved phone numbers will be
     gone"), plus the reassurance that the backup is already saved in `exports/` either way,
     ending with an explicit **yes** to proceed (the module's confirm pattern, verbatim).
     **No confirm → no push.**

**5. Push = deploy — then verify, not assume.** Commit and `git push` (to `main`; there is no
other branch). Then prove it, in order:

1. **The push auto-deployed:** poll Vercel for the new deployment — the build takes a few
   minutes, and right after the push the production domain still serves the previous one —
   until `vercel inspect <deployment-url>` shows the pushed commit SHA (`git rev-parse HEAD`).
   No new deployment ever arriving, or the SHA never matching once the build settles, means
   continuous deployment broke. Check the cheap cause first: **is the current production
   deployment a rollback?** The Vercel dashboard → **Deployments** shows it, the same way step 1
   does — the **Undo Rollback** affordance is what a rolled-back project offers. If it is, this
   is the named drift state below, not a broken webhook: the owner pressed the button this skill
   told them about, and pushes have been building without going live ever since. Step 1 should
   have caught and settled that, and only one undo is this visit's to make — do the
   follow-through's second half (**Undo Rollback**, or `vercel promote`) and re-verify **only
   when the push just made is the fix or revert for whatever caused the rollback**. That is
   convention 4's both-halves rule and nothing looser. Any other change — today's notes box
   sitting on top of last week's bad commits — is not this visit's to undo blind, because Undo
   Rollback promotes everything now on `main`: say that to the owner and get the broken change
   fixed or reverted first. One case is not a failure at all: where the owner declined the undo
   at step 1 — code-only work, by step 2's rule — a deployment that exists and built with the
   pushed SHA while production still serves the older version **is this visit's success**. Stop
   here rather than re-polling; check 2 below still reads against what is actually serving, and
   check 4 waits. Only a mismatch with no rollback in play is a `deploy-doctor` finding, and
   neither is ever papered over with a CLI deploy.
2. **Live URL returns 200** — the production domain, read from the Vercel project's Domains
   settings, never assumed to be `<slug>.vercel.app` and never a preview URL.
3. **The migration applied** (whenever the change touched schema): probe the REST API for the
   change, shaped to what the migration did — a new table or column answers a probe query
   (`GET <SUPABASE_URL>/rest/v1/<table>?select=<new-column>&limit=1` with the publishable key,
   `NEXT_PUBLIC_SUPABASE_ANON_KEY` from `.env.local` → 200); a drop or rename shows up as the
   old shape *disappearing* from the same probe or from the `GET /rest/v1/` OpenAPI output
   (module: the change must be visible through the REST API). The apply lags the push — poll
   for a few minutes. **URL 200 alone never counts** (convention 3).

   A probe that never flips means the migration did not run — **and the code that needs it is
   already live**, so assume the app is broken for real visitors until proven otherwise. Say
   that to the owner in those words, then roll the code back (one click, below) so the site
   serves the version that matches the schema it actually has. Fix the migration, push, and
   undo the rollback — both halves, as always. Debugging a migration while the owner's
   customers meet a 500 is the one thing worse than the failed migration.
4. **The changed thing works:** open the touched page on the live URL and check the change is
   actually there — except on the declined-undo path, where the change is deliberately not live
   yet and this check waits until the rollback is undone. A change that touched auth re-runs the
   module's owner smoke test (owner sends themselves the magic link in their own browser, lands
   on `/owner`). A change that
   switched **custom SMTP on** re-runs it after the switch, without exception: from that moment
   every auth email leaves through the new sender, so a wrong API key or an unverified sending
   domain breaks the owner's own sign-in — the one that was working before this visit. Link
   not sent, or sent and never arrived, is not done; turn the custom sender back off until it
   is right, rather than leaving the owner locked out of their own app.

Each check that ran is announced as it passes, opening with its fixed label — **"Check 1 of
4 — deployed by the push"**, **"Check 2 of 4 — the site answers 200"**, **"Check 3 of 4 — the
database change applied"**, **"Check 4 of 4 — the change is live on the page"**. Fixed for the
same reason as `app-builder`'s proof labels: the worked examples (`examples/`) and the nightly
QA fixtures (`qa/worked-examples/`) quote and key on them. A check this visit doesn't have —
no schema change, or the declined-undo path where check 4 waits — is said in a sentence, never
skipped silently.

All that pass = done. Any failure is fixed and re-verified — or recovered (below) — never
talked around. A stated outcome the owner chose, like the declined undo above, is not a failure
and is never treated as one.

**6. Close the loop with the owner.** Branch on what this visit actually did.

**A change that pushed code or schema:** the same URL has the new behaviour — say what to look
at. Remind them once: *"if this change turns out wrong, one click rolls the code back to the
version before this one — and tell me straight after you press it, because new changes stop
going live until I put the deploys back on track. Your data from before the change is saved in
`exports/` on this computer — deliberately, since it's your customers' data and it never goes
into the repo, so copy that folder somewhere safe if it matters."* (Only say the second half
when step 4 actually made an export.) If the owner declined the rollback undo, close on the
truth instead: what was pushed, that it is built and waiting rather than live, and that undoing
the rollback — one click, whenever they say — both puts it live and is when the two of you look
it over.

**A dashboard-only visit** — the custom-SMTP switch: nothing was pushed, so never say the URL
has new behaviour, and **never offer the rollback button here**. Convention 4's rollback
restores code, and it cannot undo a setting inside the owner's Supabase project — offering it
would be promising an undo the button does not deliver. Say what actually changed, and what
undoing it really means: *"the app itself is unchanged — what changed is in your Supabase
settings: sign-in emails now go out through your own sender instead of the free built-in one,
and nobody new can sign themselves up. If you want that undone it's those same settings put
back, and I'll do it whenever you ask."*

**Either way, if the business-use gate fired on this visit, say the answer back** — this skill
renders no next-steps card, so this is the only place the answer is recorded. On **(a)** not
business use yet: the free tier is a personal-audience evaluation, days not months, and a
business app runs on Pro — **Vercel Pro ($20/mo)** and **Supabase Pro ($25/mo plus usage-based
compute, never a flat $25)** — said once, here, rather than discovered in a bill. On **(b)**
upgrade now: confirm which upgrades were actually done, so the owner leaves knowing exactly
what they are paying for.

## When a change goes wrong — the two recovery moves

Both of these are said to the owner in plain English, with their limits, at the moment they're
needed. Never promise more than they deliver.

**Code — Vercel one-click rollback.** Vercel dashboard → Deployments → the previous production
deployment → **Instant Rollback**. Instant, no git knowledge needed; this is what makes
main-only safe. Its honest limits (convention 4):

- It reaches exactly **one step back** on the free plan. Two bad pushes in a row → the recovery
  is a revert commit pushed to `main` (Claude does this), not the button.
- **Rollback is a stopgap, not the end state.** After it, Vercel switches off automatic
  production deploys — new pushes build but don't go live. The follow-through is always both
  halves: push a fix or revert commit to `main`, **and** undo the rollback (dashboard **Undo
  Rollback**, or `vercel promote` — sanctioned exactly here, because it restores push = deploy
  rather than bypassing it). Until both halves land, the app sits in the named drift state
  *rolled back with auto-deploy off*.
- **Rollback restores code, not data.** A migration that dropped a column is untouched by it.

**Data — Claude-assisted restore from the pre-migration export.** The export step 4 made is the
data recovery path: `exports/<timestamp>_pre-migration/` holds each affected table as `.csv` +
`.sql`. Honest scope, said up front: this is **assisted restore, not an undo button**. A
post-drop restore needs schema surgery — first a new committed migration recreating the dropped
table or column (pushed, like any schema change), then replaying the exported rows. Claude
walks the owner through it; the data comes back, but it is a repair job, not a click.

## Rules quoted from CONVENTIONS.md

- **Convention 1** — one repo per app; the repo is what exists, a laptop directory is a cache
  of it. Never a second Vercel project on the repo.
- **Convention 2** — `main` is production; main-only, no branches, no PRs.
- **Convention 3** — push = deploy for code **and** schema; never `vercel deploy`; never deploy
  from an unlinked directory (that silently creates a second Vercel project — which is why
  step 1 stops rather than links blind); schema changes only from committed migrations; "done"
  = pushed commit auto-deployed + live URL 200 + migration applied.
- **Convention 4** — the undo is Vercel one-click rollback, **code only**, one step back on
  the free plan, with the both-halves follow-through; destructive = named-loss confirm +
  automatic pre-migration export before the push; data recovery is Claude-assisted restore,
  honestly scoped.
- **Convention 5** — env vars live in Vercel; locally `vercel env pull`; no secrets in the
  repo, ever.
- **Convention 6** — one Supabase project per app, two free-tier cliffs, and a separate
  business-use trigger. Cliff 1, the roughly two-active-projects cap, lands on `app-builder`,
  which checks the count before creating a project; this skill creates none. What lands here is
  **cliff 2** — projects **auto-pause after about a week idle**, which is why step 1 checks the
  database is awake — and the **business-use trigger**, which fires both upgrades
  unconditionally (Vercel Pro $20/mo and Supabase Pro $25/mo plus usage-based compute, never
  quoted flat), which is why the gate above runs before the work, not after it. Cliff 2 also
  carries the day-30 rule — a static route plus a management-API status check, because a
  DB-touching ping resets the idle timer and fakes its own evidence — which is why the template
  ships `/up` and why step 3 keeps it static and out of the proxy on every visit.
- **What is off-path** — a deploy-target or workflow ask outside the path (a foreign host,
  dashboard SQL, a staging branch, …) gets that table's redirect, opened with the fixed words
  **One blessed path** and naming `CONVENTIONS.md`.

## Data + auth

`modules/data-auth/MODULE.md` owns everything database-shaped — migration naming,
additive-vs-destructive rules, the export script, the owner-only magic-link gates and the
custom-SMTP step, the storage pattern. Steps 3–5 and the SMTP gate carry the module's actions in
run order so an iterate never has to leave this file; `MODULE.md` holds the canonical form, and
where the two diverge, `MODULE.md` wins — with **one deliberate exception, recorded here**:
the module also describes widening access at the `isOwnerEmail` predicate once custom SMTP is
in place. This skill does not do that in v1 (see *Customer sign-in* above). Where the module
describes the wider path it is describing work that has not been built — per-user storage
policies and re-enabled signups belong with it — not work to improvise on a live business app
during a change request.

## Not this skill

- An app that doesn't exist yet — `app-builder`.
- Listing apps, share help, still-alive checks — `app-status`.
- Letting customers create their own accounts — owner-only is v1's answer and this skill says
  so (see *Customer sign-in* above). It sets up custom email; it never widens `isOwnerEmail`,
  re-enables signups, or writes per-user storage policies.
- Continuous deployment found broken, env/key drift, a paused Supabase project found on an app
  this skill isn't changing, apps built outside the pack — `deploy-doctor` (M4). This skill
  verifies its own pushes and clears the drift it caused — a rollback left un-undone, a project
  it found asleep on arrival; the doctor owns everything else.
- Accounts, CLIs, SSO — `github-provision` / `vercel-provision` / `supabase-provision` via
  `app-foundation-setup`.
- CWK's `deploy-to-vercel`, `vercel-deployment`, `cloudflare-deployment`, `render-deployment`,
  `railway-deployment` — the pack deploys only by pushing to `main` (convention 3); a change
  to a workshop app routes here, never to a deploy skill.
- CWK's `supabase-admin` — the module owns schema/auth doctrine; its developer-facing flow has
  no destructive-confirm or Docker-free export.
- CWK's `github-connector` — repo access here rides the `gh` auth `github-provision` set up;
  no PAT minting, no separate GitHub connection.
