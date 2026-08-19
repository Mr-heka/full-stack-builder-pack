---
name: vercel-provision
description: Detection-first Vercel connector — refuses to run before GitHub is done, then probes vercel whoami and the browser session, and asks at most one question ("have you created a Vercel account before?"), only when every probe comes back empty. Delivers a Vercel account on Hobby via Continue-with-GitHub, the vercel CLI authenticated by device flow, and the Vercel GitHub app installed at All-repositories scope — deploy-ready. Use after github-provision, or any time Vercel account/CLI/app state is unknown — re-runs detect everything and ask nothing.
---

# vercel-provision

Done means: a Vercel account on **Hobby** that signs in with **Continue with GitHub** as the same
account gh is authenticated into; the vercel CLI logged in; and the Vercel GitHub app installed for
the owner's account at **All repositories** — the state where push = deploy is real (convention 3)
and `app-builder` can create the first project with no browser detour. Created accounts are born
with no Vercel password: GitHub is their identity (convention 7).

Every step opens with its detect and skips what already passes (the registry's rule: detect from
the world, no state file — re-running is always safe). Browser work routes through
`browser-connect`: handoff links open pinned to the owner's daily profile, and a driven browser
is the owner's own connected one (extension mode, the mainline) or a kit-owned fallback profile
that dies with the run — the contract in [The browser](#the-browser) below (convention 7).

## GitHub first — a hard gate

`gh auth status` exits non-zero or shows no active github.com account → stop, one line: "GitHub
isn't set up yet — run `github-provision` first; Vercel signs in through it." Nothing else runs
until that passes. Note the active login it prints: every "the owner's GitHub account" below means
that value.

## Detect, don't ask

Tooling first, silently: `node --version` v20+ and `vercel --version` — macOS `brew install node`
then `npm install -g vercel`; Windows `winget install --id OpenJS.NodeJS.LTS -e` then the same npm
install; fresh shell after installs. Then probe, stopping at the first hit:

1. **CLI** — `vercel whoami` prints a username → account and CLI both done; announce the pair —
   "Vercel CLI signed in as `<vercel-user>`, GitHub as `<login>`" — and skip to
   [The GitHub app](#the-github-app). The Vercel username needn't match the GitHub login — Vercel
   mints its own slugs — so a differing name is not a mismatch and never a failure. One extra
   read: the CLI's active scope (`vercel teams ls`, the ✔ row) must be the owner's own team — a
   shared machine can leave it pointed at someone else's, where every project `app-builder`
   creates would land; `vercel switch` to the owner's team if so.
2. **Browser** — a live vercel.com session in the driven browser (the dashboard renders instead of
   redirecting to login) → the account exists; announce it, skip signup, go to
   [CLI login](#cli-login).
3. Both empty → the one question: **"Have you created a Vercel account before? Yes, no — and not
   sure is a fine answer too."**
   - **No** or **not sure** → [Sign-up](#sign-up) — it detects an existing account on its own
     and falls through to adopt, so "not sure" costs nothing.
   - **Yes** → adopt: the owner signs in at vercel.com the way that works today (hands-off while
     they type). A sign-in that is not Continue-with-GitHub — email + password, or another provider
     — gets the GitHub account connected at Account Settings → Authentication **before** any SSO
     attempt: SSO tried first misses the account and silently mints a duplicate. Then
     [CLI login](#cli-login).

What a probe finds is announced and adopted, never re-asked. Re-running this skill on a finished
machine is free: every probe passes, the [proof block](#proof-of-done) prints, nothing is asked.

## The browser

The browser the owner's GitHub session already lives in: in extension mode their own daily
browser, so Continue-with-GitHub is one click, not a re-login; on the kit-profile fallback a
profile created fresh for this run, which by construction carries no prior session, so the GitHub
sign-in repeats there — that cost belongs to the fallback, not the mainline. Sessions found are
detection, not contamination — announced and adopted, never signed out. One heads-up line the
first time a browser page opens this run and again before any sign-in page, and the hands-off
window — no reads, no screenshots, no keystrokes — whenever the owner is typing a password or
code, until they say done.

**Which browser gets driven — and its teardown.** The mode comes from the BROWSER check's pin
(`~/.fsbp/browser.json`), set at install by `browser-connect`; teardown is mode-dependent
(convention 7).

**Extension mode — the mainline.** The driven browser is the owner's own everyday one, attached
through the Playwright MCP Bridge extension in their pinned profile. Their real sessions are in
view, so `browser-connect`'s conduct rules govern: session-state reads are free and announced —
detection-first, "already signed in as X" is a PASS to surface, never contamination — form-fill
and navigation happen only where the steps below spell them out, and any click that grants,
authorizes, or pays is the owner's, kept human as a consent choice rather than a technical limit.
Navigating to a live OAuth Authorize page on a signed-in account is itself treated as a consented
step: a previously-authorized grant can auto-complete the moment it loads. Teardown is a
disconnect — nothing was created in that browser, nothing is deleted from it, ever — and the
report line is **connected to your own browser — nothing created, nothing to delete**.

**Kit-profile fallback** — the pin says `kit-profile` (no Chrome/Edge, or the owner declined the
extension). A browser Claude launches runs on a dedicated automation profile
**created fresh for this run** — never the owner's own, and never a shared or canonical automation
profile that other sessions reuse; deleting one of those would be worse than deleting nothing. Give
it a per-run name under one fixed parent — `~/.fsbp/browser-profiles/`, which on Windows is
`%USERPROFILE%\.fsbp\browser-profiles\` — created if it isn't there already, and **name the
profile's full path out loud when the browser opens**, so teardown and the report can both find it
and so a run that never ends — a crash, a closed laptop, an owner who walks away — leaves a path
the next run can sweep. That parent is the same one for both provisioners and for every run:
choose a different one and the sweep looks where the leftover isn't. Before opening a browser of
this run's own, sweep any leftover under that parent that no live browser process still holds — and
where one of those leftovers is a path a FAILED teardown line already named to the owner this
session, tell them it has now been cleaned up, so the last thing they heard doesn't send them to a
folder that is already gone. When provisioning ends — pass or fail — close that browser, delete
its profile directory, and confirm the directory is gone. That is what clears the **browser end**
of the chain: the GitHub session that signed everything in lives in that profile too. The CLI
tokens minted this run stay where their CLIs put them — that is the point of provisioning, and the
consent lines already said so. Still there — a file locked open, a browser process that outlived
the close — retry once after killing the browser process; still there after that, say so plainly,
name the full path, and tell the owner to delete that folder themselves before they leave. Never
report a teardown that did not happen.

**The Authorize rule.** Third-party grants — the **Authorize Vercel** screen on github.com — get
one line first ("this lets Vercel see your GitHub account — that's what connects them"), then the
owner clicks: a grant click stays human in every mode. In the owner's own browser (extension
mode) that is a consent choice, kept deliberately, not a technical limit; in an
automation-launched browser GitHub keeps the button disabled regardless, so it could not be
Claude's anyway. Never force-enable the button from JavaScript — that ships a consent bypass.

**The wrong-session trap.** Before any Continue-with-GitHub click, app-install click, or
app-page read, the browser's GitHub session must be the gh-authenticated account — SSO chains, and
GitHub renders app pages for, whichever session the browser holds. A different account signed in →
announce it and let the owner switch; never silently proceed.

## Sign-up

Claude drives end-to-end; the owner touches nothing but the grant clicks, which are theirs by
[the Authorize rule](#the-browser):

1. Preflight, this branch only: the GitHub **primary email** must show `verified: true` — an
   unverified email fails Vercel's signup midway with an error that blames the wrong thing. Detect
   via `gh api user/emails` (the primary entry's `verified` flag). A 404 means the token lacks the
   `user` scope — a login through github-provision's Connect already carries it; an older token
   gets `gh auth refresh -h github.com -s user`, heads-up line first, same device-code
   choreography. Unverified → resend from <https://github.com/settings/emails>, the owner clicks
   the link in their inbox, re-detect once; still unverified or no mail arriving → the FAIL line,
   and stop — signup cannot proceed past GitHub's own bar.
2. Heads-up line, open <https://vercel.com/signup>, choose **Hobby**, fill the name — and the
   **Continue with GitHub** click is the owner's: it starts a grant, so it stays human.
3. GitHub asks for the grant → [the Authorize rule](#the-browser).
4. Vercel reporting an account already associated with the GitHub email (however worded) → the
   account exists: switch to <https://vercel.com/login> → Continue with GitHub, and continue as
   adopt. This is the "not sure" branch resolving itself.
5. Landing on the dashboard is the proof: account created on Hobby, no Vercel password, GitHub as
   its identity.

## CLI login

`vercel login` runs a device flow: it prints `https://vercel.com/oauth/device?user_code=XXXX-XXXX`
and waits. Open that URL in the driven browser — the dashboard session is already there — and
confirm; or hand the link over ready to click. Re-detect: `vercel whoami` prints the username. The
token lands in the vercel CLI's own auth file; nothing is minted by hand, nothing read back.

## The GitHub app

What makes push = deploy real. The only trustworthy detect is a browser read —
`gh api user/installations` returns 403 for OAuth tokens (verified), so there is no CLI detect.
In the browser, as the owner's GitHub account ([the wrong-session trap](#the-browser)), open
<https://github.com/apps/vercel>:

- Button reads **Install** → not installed. Installing the app is a grant, so the click is the
  owner's ([the Authorize rule](#the-browser)): they click **Install**, choose their own account,
  scope **All repositories**, confirm; GitHub hands back to vercel.com to finish. All
  repositories is the blessed scope: every future app repo (one repo per app, convention 1)
  deploys with no per-app detour.
- Button reads **Configure** → an installation exists somewhere, which says nothing about scope
  yet: open it and confirm the owner's own account is an install target at **All repositories** —
  a read, Claude's to run and announce. Narrower scope → the owner widens it on that same page (a
  grant again). Installed only for an org or another account → run the Install path for the
  owner's account.

Any authorize screen here follows [the Authorize rule](#the-browser). Re-detect: **Configure**,
owner's account, **All repositories**.

## Proof of done

One compact block, read fresh from the world:

- `vercel whoami` — the account — and the active scope is the owner's own team.
- Plan: **Hobby** — read from the vercel.com dashboard while the browser is up for
  [The GitHub app](#the-github-app). A paid plan already in place passes with a note; a run that
  drove no browser marks the row unverified rather than failing it.
- GitHub app: installed for the owner's account, **All repositories**.
- The teardown line, when any browser was driven this run: **connected to your own browser —
  nothing created, nothing to delete** (extension mode), profile deleted (with the path), or
  teardown FAILED (with the path and what the owner must delete by hand).
- One line: "Vercel is deploy-ready — the next pushed repo `app-builder` links would go live."

Anything that could not be fixed prints **instead of** the done-line, as
`FAIL — <what> — <who acts next>` — never silently deferred.

## Rules quoted from CONVENTIONS.md

- **Convention 7** — GitHub SSO chains identity; hands-off window during credential entry;
  browser access through `browser-connect` with mode-dependent teardown: disconnect-and-delete-
  nothing in the owner's own browser, fresh-profile-deleted-after on the kit fallback.
- **Convention 3** — never `vercel deploy`. This skill deploys nothing and creates **no Vercel
  project**.
- **Hobby is the starting plan.** The Vercel Pro ($20/mo) conversation belongs to the business-use
  gate (`STACK.md`), not to provisioning.

## Not this skill

- Which browser, which profile, which driver — `browser-connect`; this skill drives whatever
  browser its mode provides and owns only the Vercel flow inside it.
- GitHub account, git identity, gh CLI — `github-provision`, the hard gate above.
- Supabase account, org, CLI — `supabase-provision`.
- The machine-wide doctor — `foundation-check`; this skill carries its own detects inline and
  installs nothing beside itself.
- Creating a Vercel project, linking a repo, deploying — `app-builder`.
- CWK's `deploy-to-vercel` — its later paths link and deploy from the CLI. The pack deploys only
  by pushing (convention 3); on a machine with both packs installed, Vercel onboarding for the
  workshop routes here.
