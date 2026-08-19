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

The same browser github-provision used — it holds the GitHub session, so Continue-with-GitHub is
one click, not a re-login. Same rules: the owner's daily browser via extension mode where the
workshop setup installed the bridge extension; fallback the persistent kit profile
`~/.fsbp/browser-profiles/default/` (Windows: `%USERPROFILE%\.fsbp\browser-profiles\default\`),
kept across runs on a single-owner machine. The machine-class test is the gate's `gh auth status`:
several accounts marks an operator or multi-account machine, where the browser runs on a
fresh-per-run profile, deleted after the run — which by construction carries no prior session, so
the GitHub sign-in repeats there; that cost belongs to operator machines, not attendees. Sessions
found are detection, not contamination — announced and adopted, never signed out. One heads-up
line the first time a browser page opens this run and again before any sign-in page, and the
hands-off window — no reads, no screenshots, no keystrokes — whenever the owner is typing a
password or code, until they say done.

**The Authorize rule.** Third-party grants — the **Authorize Vercel** screen on github.com — get
one line first ("this lets Vercel see your GitHub account — that's what connects them"), then the
click comes from a human hand or an honestly enabled button: in an automation-launched browser
GitHub keeps the button disabled, so the owner clicks; in the owner's own browser (extension mode)
Claude may click it. Never force-enable the button from JavaScript — that ships a consent bypass.

**The wrong-session trap.** Before any Continue-with-GitHub click, app-install click, or
app-page read, the browser's GitHub session must be the gh-authenticated account — SSO chains, and
GitHub renders app pages for, whichever session the browser holds. A different account signed in →
announce it and let the owner switch; never silently proceed.

## Sign-up

Claude drives end-to-end; the owner touches nothing but the clicks the browser reserves for humans:

1. Preflight, this branch only: the GitHub **primary email** must show `verified: true` — an
   unverified email fails Vercel's signup midway with an error that blames the wrong thing. Detect
   via `gh api user/emails` (the primary entry's `verified` flag). A 404 means the token lacks the
   `user` scope — a login through github-provision's Connect already carries it; an older token
   gets `gh auth refresh -h github.com -s user`, heads-up line first, same device-code
   choreography. Unverified → resend from <https://github.com/settings/emails>, the owner clicks
   the link in their inbox, re-detect once; still unverified or no mail arriving → the FAIL line,
   and stop — signup cannot proceed past GitHub's own bar.
2. Heads-up line, open <https://vercel.com/signup>, choose **Hobby**, fill the name, click
   **Continue with GitHub**.
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

- Button reads **Install** → not installed: click it, choose the owner's account, scope **All
  repositories**, confirm; GitHub hands back to vercel.com to finish. All repositories is the
  blessed scope: every future app repo (one repo per app, convention 1) deploys with no per-app
  detour.
- Button reads **Configure** → an installation exists somewhere, which says nothing about scope
  yet: open it and confirm the owner's own account is an install target at **All repositories**.
  Narrower scope → widen it on that same page. Installed only for an org or another account → run
  the Install path for the owner's account.

Any authorize screen here follows [the Authorize rule](#the-browser). Re-detect: **Configure**,
owner's account, **All repositories**.

## Proof of done

One compact block, read fresh from the world:

- `vercel whoami` — the account — and the active scope is the owner's own team.
- Plan: **Hobby** — read from the vercel.com dashboard while the browser is up for
  [The GitHub app](#the-github-app). A paid plan already in place passes with a note; a run that
  drove no browser marks the row unverified rather than failing it.
- GitHub app: installed for the owner's account, **All repositories**.
- One line: "Vercel is deploy-ready — the next pushed repo `app-builder` links would go live."

Anything that could not be fixed prints **instead of** the done-line, as
`FAIL — <what> — <who acts next>` — never silently deferred.

## Rules quoted from CONVENTIONS.md

- **Convention 3** — never `vercel deploy`. This skill deploys nothing and creates **no Vercel
  project**.
- **Convention 7** — GitHub SSO chains identity; hands-off window during credential entry.
- **Hobby is the starting plan.** The Vercel Pro ($20/mo) conversation belongs to the business-use
  gate (`STACK.md`), not to provisioning.

## Not this skill

- GitHub account, git identity, gh CLI — `github-provision`, the hard gate above.
- Supabase account, org, CLI — `supabase-provision`.
- The machine-wide doctor — `foundation-check`; this skill carries its own detects inline and
  installs nothing beside itself.
- Creating a Vercel project, linking a repo, deploying — `app-builder`.
- CWK's `deploy-to-vercel` — its later paths link and deploy from the CLI. The pack deploys only
  by pushing (convention 3); on a machine with both packs installed, Vercel onboarding for the
  workshop routes here.
