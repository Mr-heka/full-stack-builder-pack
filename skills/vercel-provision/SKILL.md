---
name: vercel-provision
description: Detection-first Vercel connector — probes vercel whoami and the owner's real browser session, fixes only what is missing, and asks nothing beyond one fallback opener ("have you created a Vercel account before?") — and only when every probe comes back empty. Where GitHub isn't done it routes to github-provision instead of asking. Delivers a Vercel account on Hobby signed in with Continue-with-GitHub, the vercel CLI authenticated by device flow into the owner's own scope, and the Vercel GitHub app connected at All repositories — deploy-ready. Use to set up Vercel on a machine, after github-provision, or to re-verify — a second run detects everything and asks nothing.
---

# vercel-provision

Done means four things, all read fresh from the world: a Vercel account on **Hobby** — one this
skill creates signs in with **Continue with GitHub** and is born with no Vercel password
(`CONVENTIONS.md` convention 7), and one detection adopts is taken as it stands, with its GitHub
connection established explicitly on the adopt path rather than assumed ([Adopt](#adopt)); the
`vercel` CLI logged into that account with the **owner's own scope** active; the **Vercel GitHub
app** connected for the owner's account at **All repositories**; and, from those,
**deploy-readiness** — the state where push = deploy is real (convention 3), so `app-builder` could
link a repo and a deployment could spin up immediately with no browser detour.

This skill is self-contained: it detects, fixes and verifies each of those inline. It installs no
other skill beside its own tooling and depends on no machine-wide doctor.

## GitHub first — routed, not asked

Vercel signs in through GitHub, so this skill's prerequisite is `github-provision`'s proof of done.
It is enforced by **routing, never by interrogation** — the attendee is not asked whether they have
GitHub set up, and never asked to go and run something. Two reads, silent:

- `gh auth status` shows an active github.com account, and
- its primary email is verified — `gh api user/emails --jq '.[] | select(.primary) | .verified'`
  prints `true`, because **Continue with GitHub requires a verified primary email** and an
  unverified one fails Vercel's signup midway with an error that blames the wrong thing. **Empty
  output**, a 404 or a scope error is the routine adopted-token case — the token cannot see emails,
  which says nothing about the email — and it routes exactly like a `false`.

Either read coming back short → say one line — "Vercel signs in through GitHub, so I'll finish
GitHub first" — then **run `github-provision`** and come back here when its proof block prints
**the done-line**. That skill prints its proof block alongside a FAIL by design, and its named FAIL
is the unverified-email case above: a FAIL there is this skill's stop too, not a green light. Every
repair — the scope top-up included — is that skill's, never redone here. Note the active login
`gh auth status` prints: every "the owner's GitHub account" below means that value.

## Detect, don't ask

Tooling first, silently ([Install](#install)). Then everything inferable is inferred, in this
order — **stopping at the first probe that finds an account**:

1. **CLI** — `vercel whoami` prints a username → account and CLI are both done. Announce the pair —
   "Vercel CLI signed in as `<vercel-user>`, GitHub as `<login>`" — and skip to
   [The GitHub app](#the-github-app). The Vercel username needn't match the GitHub login; Vercel
   mints its own slugs, so a differing name is not a mismatch and never a failure. One fact this
   unlocks rather than a further probe: the CLI's active scope (`vercel teams ls`, the ✔ row) must
   be the owner's own — their personal scope on a fresh Hobby account, or their own team where one
   exists. Someone else's team is the failure, since every project `app-builder` creates would land
   there on a shared machine; an empty team list is not a failure. `vercel switch` if it is wrong.
2. **Browser** — the vercel.com session in the owner's own browser, read through
   [the browser](#the-browser) and announced as it happens. Only when probe 1 came back empty.
   <https://vercel.com/signup> **silently redirecting into the dashboard** is the signal: a session
   exists, so the account exists. That is a detect PASS, not a hazard — announce it, skip signup,
   and go to [Connect](#connect). No driver connected (rung 1) → open <https://vercel.com/> pinned
   and let the owner say which account, if any, it shows.

What a probe finds is **announced and skipped** — "you already have a Vercel account, skipping
straight to the CLI login" — never re-asked, never treated as a problem. An account or session that
detection finds is the owner's world: adopt it, **never sign it out**. Re-running this skill on a
finished machine is free and silent: probe 1 passes, the [proof block](#proof-of-done) prints, **no
question is asked, no account is created and nothing re-authenticates**.

**The one question** — the single fallback opener, asked only when every probe comes back empty:
**"Have you created a Vercel account before? Yes, no — or I don't know, and I'll go and look."**

- **Yes** → [Adopt](#adopt): the account exists but no session was found, so the browser step is a
  sign-in, not a signup.
- **No** → [Create](#create).
- **I don't know** → Claude looks, in the browser, rather than handing the question back. Vercel
  gives no inline "that email is taken" the way GitHub's signup field does, so the look **is the
  Continue-with-GitHub move itself**, which answers either way and wastes nothing: run
  [Create](#create) from step 1 and read what comes back. An account already on that identity
  resolves as either the dashboard loading straight away, or Vercel saying there is **already an
  account associated with your GitHub email address** (however worded) — in both cases the account
  exists, so adopt it and continue at [Connect](#connect). No account → the same run keeps going and
  creates one. Say which identity is being checked before looking — the GitHub login and its primary
  email — so the owner can correct it if it isn't the address they'd have used. This look is safe
  **because nobody knows of an existing account**; the moment the owner recalls one they sign into
  with an email and password, stop and take [Adopt](#adopt) instead — Continue-with-GitHub run first
  against an email-and-password account is what mints the duplicate.

That is the whole interview. Plan, username, scope and app-install state come from the world — never
asked, and never taken on the owner's word.

## The browser

Browser access routes through the pack's `browser-connect` skill, which owns which browser, which
profile and which driver. The mainline is **extension mode** — the driver attached to the owner's
own already-running Chrome or Edge, where `navigator.webdriver` is false and sites that score
automation behave normally. A browser the agent *launches* is the fallback rung, with its known
limits. Rules that bind in every rung:

- **Claude drives the pages; the owner types only what is theirs to type.** Navigation, choosing
  Hobby, filling the account name, opening the device page, reading the app-install page — Claude's.
  The owner's hands are needed at exactly one kind of moment: a grant click
  ([the anchor](#the-human-anchor)) — three of them at most — plus their own credentials wherever a
  sign-in or an OS password prompt asks for them.
- **No driver, no dead end.** Rung 1 — pinned handoff links, always on, nothing driven — is a
  degraded path, not a stop: every step below that says "Claude drives" becomes "the page opens
  pinned, ready, and the owner does that one thing and says when it's done". Every step keeps its
  rung-1 form; nothing in this skill requires the extension, and this skill never installs it.
- **Sessions found are detection, not contamination.** A logged-in Vercel or GitHub account
  discovered in the browser is announced and adopted — never signed out, never cleaned up.
- **The heads-up line.** The first time a page opens in the owner's browser this run, and again
  before any sign-in page: one line — "opening Vercel sign-in; it goes through GitHub, so there's no
  new password" — then open it. One line, not a consent recital.
- **The hands-off window.** The moment the owner is handed a password, a two-factor prompt, an
  authorize screen, or anything GitHub or Vercel asks for to prove it is them, Claude goes
  completely hands-off — no reads, no screenshots, no keystrokes — until the owner says they're
  done. The window covers the entry, not the outcome: once they say done, reading the page it landed
  on is how the run resumes, and every step below that reads a result reads it there.
- **Every handoff link opens pinned** to the detected daily browser and profile, by naming the
  browser binary with `--profile-directory` (a non-Chromium daily browser has no profile routing to
  get wrong — open it by name; `browser-connect` has the exact forms). Bare `open` / `start` /
  `xdg-open` is banned: a running Chrome routes those to whichever window last had focus, which is
  the wrong-profile misroute. That ban covers opens a *CLI* makes on Claude's behalf.
- **Same browser as GitHub.** This is the browser `github-provision` already signed into, which is
  why Continue-with-GitHub is one click and **no second login is needed**. On the rung-3 kit profile
  — created fresh for the run, so it carries no prior session by construction — the GitHub sign-in
  repeats there; that cost belongs to the fallback, not the mainline.
- **The wrong-session trap.** Before any Continue-with-GitHub click, app-install click, or app-page
  read, the browser's GitHub session must be the gh-authenticated account: SSO chains, and GitHub
  renders app pages for, whichever session the browser holds. A different account signed in →
  announce it and let the owner switch; never silently proceed.
- **Teardown, by rung.** Extension mode created nothing — the browser and its sessions are the
  owner's, so teardown is disconnecting and saying so. A rung-3 kit-owned profile is deleted at the
  end of the run and confirmed gone, with the path named in the [proof block](#proof-of-done);
  never report a teardown that did not happen. Still there after a retry — a file locked open, a
  browser process that outlived the close — say so plainly, name the full path, and tell the owner
  to delete that folder themselves before they leave.

### The human anchor

One, and only one: **a grant click.** Every grant in this skill is the same click in three places —
**Authorize Vercel** on github.com during signup, **Install** (or a scope widen) on the Vercel
GitHub app page, and **Confirm** on the Vercel device page.

- It is GitHub's or Vercel's own consent screen, and it stays the owner's click as a deliberate
  consent choice, matching `browser-connect`'s rule that any click that grants, authorizes or
  deletes is the owner's. For **Authorize Vercel** specifically that is also a technical fact in the
  fallback rung: in an automation-*launched* browser GitHub keeps that button disabled regardless,
  so it could not be Claude's there anyway, while in the owner's real browser it is enabled from
  first paint and drivable. The other two — the app-install click and the device-page Confirm —
  carry no such block; they are the owner's by the consent rule alone.
- **Never force-enable a disabled grant button from JavaScript.** The server accepts the POST; that
  is precisely why shipping it would ship a consent bypass.
- **Reaching that page is itself the consented step** — a grant already given once can auto-complete
  the moment the page loads, so the Claude click that lands on it is announced as "this lands you on
  GitHub's Authorize screen" before it happens, and Claude never clicks the grant button afterwards.

One line of context, then their click. Everything else on every page is Claude's to do.

## Install

`node --version` prints v20 or newer and `vercel --version` prints **51.7 or newer** — the floor for
the device flow [Connect](#connect) depends on — or fix silently: macOS `brew install node` then
`npm install -g vercel@latest`; Windows `winget install --id OpenJS.NodeJS.LTS -e` then the same npm
install, which is also the one-command fix for a CLI that is present but older than the floor. A
Mac without Homebrew gets Homebrew first (the one
command on <https://brew.sh>) — heads-up line, owner types their password for it. A CLI installed
this run is invisible to the current shell — re-detect in a fresh shell invocation.

## Create

Signup is Claude's end to end; the owner touches nothing but the one grant click:

1. Heads-up line, then open <https://vercel.com/signup> — pinned. A silent redirect into the
   dashboard here is [detection](#detect-dont-ask) answering, not a failure: the account exists,
   announce it and go to [Connect](#connect).
2. **Continue with GitHub — never email and password.** Vercel offers an email signup; it is
   off-path, because GitHub is the chained identity (convention 7) and an email-signed-up account
   arrives without the GitHub link every later step needs. Claude clicks Continue with GitHub,
   announcing that it lands on GitHub's Authorize screen.
3. GitHub asks for the grant → [the anchor](#the-human-anchor). Already granted once → the page
   auto-completes on load and there is nothing to click.
4. **Hobby** is the plan, chosen by Claude, no question: it is the starting plan for the workshop,
   and the Pro conversation belongs to the business-use gate (`STACK.md`), not to provisioning. Fill
   the account name from the GitHub profile; a name Vercel says is taken gets a suffix, silently.
5. Vercel reporting **an account already associated with your GitHub email address** (however
   worded) → the account exists on that identity; switch to <https://vercel.com/login> → Continue
   with GitHub and continue as adopt at [Connect](#connect). Worth knowing where this comes from:
   Vercel **normalizes plus-aliases**, so `name+anything@domain` and `name@domain` are one identity
   to it — which makes this error the expected answer on a mailbox that already owns an account,
   never a sign that something broke.
6. Landing on the dashboard is the proof: account created on Hobby, no Vercel password, GitHub as
   its identity.

Rung 1 → each page opens pinned in turn and the owner does the one thing on it — clicks Continue
with GitHub, picks Hobby, confirms the name — saying when each is done, and reading back what Vercel
said if step 5's error appears. Nothing here is a dead end without a driver.

## Adopt

The account exists but nothing signed in was found — the **Yes** branch of
[the one question](#detect-dont-ask). Heads-up line, then open <https://vercel.com/login>, and the
owner signs in **the way that works for them today**, hands-off while they type.

- Their sign-in is **Continue with GitHub** → the identity is already the right one; go to
  [Connect](#connect).
- Their sign-in is **email and password, or another provider** → the account has no GitHub
  connection yet, and it gets one at **Account Settings → Authentication** *before* Continue with
  GitHub is tried anywhere in this run. SSO attempted first does not find that account — it mints a
  **second, duplicate** account on the same person, which is the failure this ordering exists to
  prevent. Claude drives to the settings page and the connect click is a grant
  ([the anchor](#the-human-anchor)); rung 1 → the page opens pinned and the owner clicks it. Then
  [Connect](#connect).

## Connect

`vercel login` runs a true device flow (CLI 51.7+), choreographed as one smooth moment:

1. **Detect before logging in — always.** `vercel login` swaps the CLI's single global token, so on
   a machine that already has a real Vercel login it would silently displace it. Probe 1 of
   [Detect, don't ask](#detect-dont-ask) is what prevents that: `vercel whoami` printing anything at
   all means **adopt it and do not run `vercel login`**. This step is reached only from an empty
   probe 1.
2. Start `vercel login` in the background. It prints
   `Visit https://vercel.com/oauth/device?user_code=XXXX-XXXX` — the code is embedded in the URL, so
   there is nothing to transcribe — and waits.
3. Heads-up line, then Claude opens that exact URL in the driven browser, which by now holds a
   signed-in vercel.com session — from probe 2, [Create](#create) or [Adopt](#adopt), which is why
   every route into this section passes through one of them. A login page appearing instead means
   that session is missing: route to [Adopt](#adopt) and come back. Rung 1 → the link is handed over
   ready to click, whole, code and all.
4. The confirm on that page is a grant → [the anchor](#the-human-anchor). A password or
   identity-challenge screen appearing → hands-off window until the owner says they're done.
5. The command exiting is what closes the moment. Re-detect: `vercel whoami` prints the username,
   and the ✔ row of `vercel teams ls` is the owner's own scope — `vercel switch` if it is someone
   else's, nothing to do if the list is empty.

The token lands in the vercel CLI's own auth file; nothing is minted by hand, nothing read back.
Already logged in → never re-authenticate.

## The GitHub app

What makes push = deploy real, and the last thing standing between this machine and a deployment.
The only trustworthy detect is a browser read — `gh api user/installations` returns 403 for OAuth
tokens (verified), so there is no CLI detect. In the browser, as the owner's GitHub account
([the wrong-session trap](#the-browser)), Claude opens <https://github.com/apps/vercel>, which
renders readably in a driven browser:

- Button reads **Install** → not connected. Claude drives to the install target page and the owner
  clicks **Install** ([the anchor](#the-human-anchor)), on **their own account**, at scope **All
  repositories**; GitHub hands back to vercel.com to finish. All repositories is the blessed scope:
  every future app repo (one repo per app, convention 1) deploys with no per-app detour.
- Button reads **Configure** → an installation exists somewhere, which says nothing about scope yet.
  Claude opens it and reads whether the owner's own account is an install target at **All
  repositories**, announcing what it finds. Narrower scope → the owner widens it on that same page
  (a grant again). Installed only for an org or another account → run the Install path for the
  owner's account.

Rung 1 → the page opens pinned and the owner reads the button back and clicks through the same two
choices. Re-detect afterwards: **Configure**, owner's account, **All repositories**.

## Proof of done

One compact block, every run, read fresh from the world:

- `vercel whoami` — the account — and the ✔ row of `vercel teams ls`: the active scope is the
  owner's own, their personal scope on a fresh Hobby account or their own team where one exists.
- Plan: **Hobby**, read from the vercel.com dashboard while the browser is up for
  [The GitHub app](#the-github-app). A paid plan already in place passes with a note; a run that
  drove no browser marks the row unverified rather than failing it.
- GitHub app: connected for the owner's account at **All repositories**, and how that was read
  (the Configure page).
- Deploy-readiness, stated as the consequence of the three rows above: a repo pushed to the owner's
  GitHub account would be linkable and deployable **right now** — nothing else has to be set up
  first. This skill still deploys nothing and creates no Vercel project (convention 3).
- Browser teardown, one line, per [the browser](#the-browser) — "connected to your own browser,
  nothing created", the kit profile path and that it is gone, or teardown **FAILED** with the full
  path and what the owner must delete by hand.
- The closing line, exactly one of the two:
  - all four things done → "Vercel is deploy-ready — the next repo `app-builder` pushes would go
    live."
  - anything unfixed → `FAIL — <what> — <who acts next>`, **instead of** that done-line, never
    alongside it and never silently deferred. The rows above it still print: what is done is
    reported as done, and only the done-*line* is withheld.

## Not this skill

- Which browser, which profile, which driver, and the connection itself — `browser-connect`.
- GitHub account, gh CLI, git identity, verified email — `github-provision`, which this skill routes
  to rather than asking about.
- Account hardening of any kind. This connector delivers account + access for today; hardening
  policy belongs to the app-building flow that consumes it, and nothing here asks about it.
- Supabase account, org, CLI — `supabase-provision`.
- Creating a Vercel project, linking a repo, deploying — `app-builder`. Never `vercel deploy`, and
  never a deploy from an unlinked directory (convention 3).
- CWK's `deploy-to-vercel` — its later paths link and deploy from the CLI. The pack deploys only by
  pushing; on a machine with both packs installed, Vercel onboarding for the workshop routes here.
