---
name: github-provision
description: Detection-first GitHub connector — probes gh auth, the GitHub API and the browser session, fixes only what is missing, and asks at most one question ("have you created a GitHub account before?"), only when every probe comes back empty. Delivers a GitHub account, git + gh installed, gh authenticated with repo and workflow scopes, and git identity set silently from the GitHub profile (noreply address when the email is private). Use to set up GitHub on a machine, before vercel-provision, or to re-verify — re-runs detect everything and ask nothing.
---

# github-provision

Done means four things, all verified from the world: a GitHub account the owner controls; git and
the gh CLI installed; gh authenticated into that account with the `repo` and `workflow` scopes; and
git identity set from the GitHub profile — the noreply address when the email is private, so the
first push never bounces off GitHub's private-email protection (GH007). This account is the
identity for everything after it: Vercel signs in with it (`CONVENTIONS.md` convention 7).

## Detect, don't ask

Everything inferable is inferred, silently, in this order — **stopping at the first probe that
finds an account**:

1. **CLI** — `gh auth status`: an active github.com account, and its token scopes. gh not
   installed yet is this probe coming back empty — [Install](#install), then re-probe.
2. **API** — `gh api user`: login, name, email (null when private or unreadable), account id.
3. **Browser** — the driven browser's github.com session, only when 1 and 2 found nothing and a
   browser tool is available.

What a probe finds is **announced and skipped** — "you're already signed in as `<login>`, skipping
straight to git identity" — never re-asked, never treated as a problem. An account or session that
detection finds is the owner's world: adopt it. Several accounts on the machine → adopt the active
one silently. Re-running this skill on a finished machine is free: probe 1 passes, the
[proof block](#proof-of-done) prints, nothing is asked and nothing re-authenticates.

**The one question** — only when every probe comes back empty: **"Have you created a GitHub
account before? Yes, no — or if you're not sure, tell me the email you usually use and I'll
check."**

- **Yes** → [Connect](#connect).
- **No** → [Create](#create).
- **Not sure** → open the signup page and enter the email they gave: GitHub answers on the spot.
  It reports the email as already taken (however GitHub words it) → an account exists →
  [Connect](#connect), with password reset as the recovery move if the password is gone. Accepted →
  no account → [Create](#create), continuing from that same half-filled form.

That is the whole interview. Name and git email come from the API; 2FA, recovery codes and backup
emails are not this skill's job ([Not this skill](#not-this-skill)).

## The browser

With a browser-automation tool available (Playwright MCP in the pack's blessed setup) Claude drives
the browser; without one it opens each page in the owner's default browser and talks them through.
Either way, the same rules:

- **The owner's daily browser is the best browser** — extension mode, riding the sessions they
  already have. Where the workshop setup installed the bridge extension, use it. Fallback: a headed
  browser on the persistent kit profile `~/.fsbp/browser-profiles/default/` (Windows:
  `%USERPROFILE%\.fsbp\browser-profiles\default\`) — persistent on purpose: on a single-owner
  machine, staying signed in across runs is the feature. The machine-class test is probe 1:
  `gh auth status` listing one account (or none) is the single-owner attendee case; several
  accounts marks an operator or multi-account machine, where cross-account linking is the real
  hazard and the browser runs on a fresh-per-run profile, deleted after the run.
- **Sessions found are detection, not contamination.** A logged-in account discovered in the
  browser is announced and adopted — never signed out, never cleaned up.
- **The heads-up line.** The first time a browser page opens this run, and again before any
  sign-in page: one line — "opening GitHub sign-in; your password stays between you and GitHub" —
  then open it. One line, not a recital.
- **The hands-off window.** The moment the owner is typing a password or a code, Claude goes
  completely hands-off — no reads, no screenshots, no keystrokes — until the owner says they're
  done.
- **Handing a link to a multi-profile Chrome:** launch the Chrome binary with
  `--profile-directory=` set to the owner's daily profile — the profile directory (under Chrome's
  `User Data`, named in `Local State`) with the largest `History` file; recency lies. A bare `open`
  routes to whichever window last had focus. Single profile → no pick to make.
- **Same browser for the whole chain.** `vercel-provision` reuses this browser and the GitHub
  session in it, so the owner signs in once.

## Install

`git --version` and `gh --version` print versions, or fix silently: macOS `brew install git gh`;
Windows `winget install --id Git.Git -e` and `winget install --id GitHub.cli -e`. Two macOS
realities: a fresh Mac answers `git --version` with the Command Line Tools dialog — that dialog
*is* the git install, tell the owner to click through it; and a Mac without Homebrew gets Homebrew
first (the one command on <https://brew.sh>) — heads-up line, owner types their password for it.
A CLI installed this run is invisible to the current shell — re-detect in a fresh shell
invocation.

## Connect

Device-code auth, choreographed as one smooth moment:

1. Start `gh auth login -h github.com --web --git-protocol https -s repo,workflow,user` in the
   background and read the one-time code from its output — the flags pre-answer every prompt.
   `repo` and `workflow` are what pushing an app template carrying GitHub Actions files needs;
   `user` is what lets the email-verified state come from the API instead of from questions.
2. Heads-up line, then open <https://github.com/login/device> and enter the code — typed by Claude
   in a driven browser, or handed over ready to paste.
3. A password or 2FA screen appearing → hands-off window until the owner says done.
4. The **Authorize github** button is GitHub's own first-party grant: click it in a driven browser,
   or the owner clicks. The login command exiting — `Logged in as <login>` — closes the moment.

Already authenticated → never re-authenticate for a scope this skill can work without: `user`
missing costs nothing here (git identity falls back to the noreply address). Only a token missing
`repo` or `workflow` — which would fail the first push — gets
`gh auth refresh -h github.com -s repo,workflow`: same device-code choreography, no new question.
Wrong account active → `gh auth switch`, never a re-login.

## Create

Account creation is the owner's moment inside Claude's choreography:

1. Heads-up line, then open <https://github.com/signup> — email pre-filled when the "not sure"
   branch already collected it — and hand over: the owner types their own email, password and
   username. Any email they like, personal or business — their call, no commentary.
2. GitHub emails a launch code; the owner reads it from their inbox and enters it. Hands-off
   throughout — the form holds their password.
3. Signup lands signed in with the email verified by the launch code itself. From here Claude
   drives every dashboard step; the owner never navigates settings pages. Continue at
   [Connect](#connect).

CAPTCHA is probabilistic — zero appearances in live testing, but GitHub scores the flow — so the
owner stays at the keyboard for signup regardless, which is also who should be typing a password.
The workshop-room rule stands: each fresh signup runs over the attendee's own phone tethering,
staggered — never several signups behind one venue IP, which flags accounts at creation.

## Git identity

Set silently from what GitHub already knows — never ask a person their name through a machine they
just signed into. From `gh api user`:

- `user.name` ← `.name`, falling back to `.login`.
- `user.email` ← `.email`; when null — email set to private, or simply unreadable by this token —
  the noreply address `<id>+<login>@users.noreply.github.com`, which GitHub accepts for any
  account and keeps a private-email account's first push from a GH007 rejection.

Only unset values are written (`git config --global`). Values already set pass as-is — announced,
not corrected. A found email GitHub later refuses (GH007 on the first push) is a one-command
repair to the noreply address at that moment, not this skill's failure to preempt.

## Proof of done

One compact block, every run, read fresh from the world:

- `gh auth status --active` — the account, and token scopes including `repo` and `workflow`.
- `git config --global user.name` / `user.email` — the values, and whether this run set them or
  found them.
- One line: "GitHub is done — account, CLI, git identity. Vercel can chain off this."

Anything that could not be fixed prints **instead of** the done-line, as
`FAIL — <what> — <who acts next>` — never silently deferred.

## Not this skill

- **Account hardening** — 2FA, recovery codes, backup emails, business-email policy. That bar
  belongs to `foundation-check` in the app-building flow (seeded by the pre-flight email), not to a
  connector: this skill delivers account + access for today.
- The machine-wide doctor — `foundation-check`. This skill carries its own detects inline and
  installs nothing beside itself.
- Vercel and Supabase sign-in — `vercel-provision` (which hard-requires this skill's proof of
  done) and `supabase-provision`.
- Creating repositories — `app-builder` owns repo creation (M2).
- CWK's `github-connector` — it mints a personal access token and registers an MCP server. The
  pack authenticates through `gh auth login` only; on a machine with both installed, "connect my
  GitHub" for workshop provisioning routes here.
