---
name: github-provision
description: Detection-first GitHub connector — probes gh auth, the GitHub API and the owner's real browser session, fixes only what is missing, and asks nothing beyond one fallback opener ("have you created a GitHub account before?") — and only when every probe comes back empty. Delivers a GitHub account, git + gh installed, gh authenticated with repo and workflow scopes, git identity set silently from the GitHub profile (noreply address when the email is private), and the primary email confirmed verified. Use to set up GitHub on a machine, before vercel-provision, or to re-verify — a second run detects everything and asks nothing.
---

# github-provision

Done means five things, all read fresh from the world: a GitHub account the owner controls; git and
the gh CLI installed; gh authenticated into that account with the `repo` and `workflow` scopes; git
identity set from the GitHub profile — the noreply address when the email is private, so the first
push never bounces off GitHub's private-email protection (GH007); and the account's **primary email
verified**, because everything downstream signs in with this account (`CONVENTIONS.md` convention
7) and `vercel-provision`'s signup fails midway on an unverified one.

This skill is self-contained: it detects, fixes and verifies each of those inline. It installs no
other skill and depends on no machine-wide doctor.

## Detect, don't ask

Everything inferable is inferred, silently, in this order — **stopping at the first probe that
finds an account**:

1. **CLI** — `gh auth status`: an active github.com account, and its token scopes. gh not
   installed yet is this probe coming back empty — [Install](#install), then re-probe. A pass here
   is followed immediately by the API reads it unlocks, which are facts rather than a further
   probe: `gh api user` for login, name, email (null when private or unreadable) and account id,
   and [email verification](#email-verification).
2. **Browser** — the github.com session in the owner's own browser, read through
   [the browser](#the-browser) and announced as it happens. Only when probe 1 came back empty. No
   driver connected (rung 1) → open <https://github.com/> pinned and let the owner say which
   account, if any, it shows.

What a probe finds is **announced and skipped** — "you're already signed in as `<login>`, skipping
straight to git identity" — never re-asked, never treated as a problem. An account or session that
detection finds is the owner's world: adopt it, never sign it out. Several accounts on the machine
→ adopt the active one silently. Re-running this skill on a finished machine is free and silent:
probe 1 passes, the [proof block](#proof-of-done) prints, **no question is asked, no account is
created and nothing re-authenticates**. The one thing a *first* run can still need on an adopted
token is a scope top-up ([Connect](#connect)) — no question, and gone by the second run.

**The one question** — the single fallback opener, asked only when every probe comes back empty:
**"Have you created a GitHub account before? Yes, no — or I don't know, and I'll go and look."**

- **Yes** → [Connect](#connect).
- **No** → [Create](#create).
- **I don't know** → Claude looks, in the browser, rather than handing the question back. Take the
  address from what the machine already knows — `git config --global user.email`, the pinned
  browser profile's own email — and **say which one is being checked**; where the machine knows
  none, that address is the one thing this branch has to be told. Then, in the driven browser, open
  <https://github.com/signup> and type it into the email field: GitHub's inline validation answers
  on the spot. No driver connected → the same page opens pinned and the owner types the address
  and reads back what GitHub says.
  Reported as already taken (however GitHub words it) → an account exists → [Connect](#connect),
  with password reset as the recovery move if the password is gone. Accepted → no account **under
  that address** — say it that way, since another address could still have one — then
  [Create](#create), continuing from that same half-filled form, or a second address checked the
  same way if the owner names one.

That is the whole interview. Name, git email and verification state come from the API — never
asked, and never taken on the owner's word.

## The browser

Browser access routes through the pack's `browser-connect` skill, which owns which browser, which
profile and which driver. The mainline is **extension mode** — the driver attached to the owner's
own already-running Chrome or Edge, where `navigator.webdriver` is false and sites that score
automation behave normally. A browser the agent *launches* is the fallback rung, with its known
limits. Rules that bind in every rung:

- **Claude drives the pages; the owner types only what is theirs to type.** Navigation, typing an
  email into a validation field, pasting a device code, clicking Continue, opening and reading
  settings pages — Claude's. The owner's hands are needed at exactly two places: their own signup
  details and credentials, and a grant click ([the anchors](#the-human-anchors)).
- **No driver, no dead end.** Rung 1 — pinned handoff links, always on, nothing driven — is a
  degraded path, not a stop: every step below that says "Claude types" becomes "the page opens
  pinned, ready, and the owner types that one field and says when it's done". Every step keeps its
  rung-1 form; nothing in this skill requires the extension, and this skill never installs it.
- **Sessions found are detection, not contamination.** A logged-in account discovered in the
  browser is announced and adopted — never signed out, never cleaned up.
- **The heads-up line.** The first time a page opens in the owner's browser this run, and again
  before any sign-in page: one line — "opening GitHub sign-in; your password stays between you and
  GitHub" — then open it. One line, not a consent recital.
- **The hands-off window.** The moment the owner is handed a password, a launch code, an authorize
  screen, or anything GitHub asks for to prove it is them, Claude goes completely hands-off — no
  reads, no screenshots, no keystrokes — until the owner says they're done.
- **Every handoff link opens pinned** to the detected daily browser and profile, by naming the
  browser binary with `--profile-directory` (a non-Chromium daily browser has no profile routing to
  get wrong — open it by name; `browser-connect` has the exact forms). Bare `open` / `start` /
  `xdg-open` is banned: a running Chrome routes those to whichever window last had focus, which is
  the wrong-profile misroute. That ban covers opens a *CLI* makes on Claude's behalf
  ([Connect](#connect)).
- **Same browser for the whole chain.** `vercel-provision` reuses this browser and the GitHub
  session in it, so the owner signs in once.
- **Teardown, by rung.** Extension mode created nothing — the browser and its sessions are the
  owner's, so teardown is disconnecting and saying so. A rung-3 kit-owned profile is deleted at the
  end of the run and confirmed gone, with the path named in the [proof block](#proof-of-done);
  never report a teardown that did not happen.

### The human anchors

Two, and only two:

- **Signup.** The owner types their own email, password and username, and the launch code from
  their inbox. GitHub scores the signup flow and CAPTCHA is probabilistic, so this stays at the
  owner's keyboard regardless — which is also who should be typing a password.
- **A grant click.** `Authorize github` on the device-code page is GitHub's own first-party grant,
  and in the owner's real browser it is technically drivable; it stays the owner's click as a
  deliberate consent choice, matching `browser-connect`'s rule that any click that grants,
  authorizes or deletes is the owner's. One line of context, then their click. **Reaching that page
  is itself the consented step** — a grant already given once can auto-complete the moment the page
  loads, so Claude's Continue click is announced as "this lands you on GitHub's Authorize screen"
  before it happens, and never force-enables or clicks the button afterwards.

Everything else on every page is Claude's to do.

## Install

`git --version` and `gh --version` print versions, or fix silently: macOS `brew install git gh`;
Windows `winget install --id Git.Git -e` and `winget install --id GitHub.cli -e`. Two macOS
realities: a fresh Mac answers `git --version` with the Command Line Tools dialog — that dialog
*is* the git install, tell the owner to click through it; and a Mac without Homebrew gets Homebrew
first (the one command on <https://brew.sh>) — heads-up line, owner types their password for it.
A CLI installed this run is invisible to the current shell — re-detect in a fresh shell
invocation.

## Create

Account creation is the owner's moment inside Claude's choreography:

1. Heads-up line, then open <https://github.com/signup> — pinned; the "I don't know" branch arrives
   here with the email already in the field, so it is not retyped — and hand over: the owner types
   their own email, password and username. **Any email they like**, personal or business, their
   call — no pushback, no commentary.
2. GitHub emails a launch code; the owner reads it from their inbox and enters it. Hands-off
   throughout — the form holds their password.
3. Signup lands signed in, with the email verified by the launch code itself. From there Claude
   drives every remaining dashboard step in that browser — any interstitial GitHub shows, and the
   settings pages needed later — so the owner never hunts through menus. Continue at
   [Connect](#connect).

The workshop-room rule stands: each fresh signup runs over the attendee's own phone tethering,
staggered — never several signups behind one venue IP, which flags accounts at creation.

## Connect

Device-code auth, choreographed as one smooth moment:

1. Start `gh auth login -h github.com --web --git-protocol https -s repo,workflow,user` in the
   background, **with `BROWSER` set to the pinned launcher** — the browser binary plus
   `--profile-directory=<pinned dir>` — because gh opens the device page itself and would
   otherwise use the OS default handler, the banned bare open. gh shell-splits `BROWSER` and
   appends the URL, and the macOS Chrome binary path contains spaces, so the binary must be quoted
   inside the value (`BROWSER='"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
   --profile-directory="Profile 1"'`) — or point `BROWSER` at a one-line wrapper script that
   execs the pinned open with `"$1"`. An unquoted path splits into the wrong argv and misroutes,
   which is the exact failure the pin exists to prevent. `repo` and `workflow` are the
   load-bearing pair: they are what pushing an app template carrying GitHub Actions files needs.
   `user` is what makes the profile email and the verified flag readable from the API instead of
   from questions — and `vercel-provision` reads them through the same token.
2. Read the one-time code from the command's output, then answer its one interactive beat — it
   waits on "Press Enter to open github.com in your browser" — by writing a newline to its stdin.
   Backgrounding it and only reading output stalls there. Heads-up line before that keypress, since
   it is what opens the page.
3. In the page — the one gh opened, or one opened pinned by hand if it did not — Claude types the
   code and clicks **Continue**, announcing that this lands on the Authorize screen. No driver
   connected → the code is handed over ready to paste and the owner does those two things.
4. A password or identity-challenge screen appearing → hands-off window until the owner says
   they're done.
5. **Authorize github** is the owner's click ([the anchors](#the-human-anchors)). The login command
   exiting — `Logged in as <login>` — closes the moment.
6. `gh auth setup-git` — idempotent, silent, no prompts — so git pushes over https authenticate
   through gh without a credential prompt Claude Code cannot answer.

Already authenticated → never re-authenticate. A token short of what the chain needs is topped up
with `gh auth refresh -h github.com -s <the missing scopes>` — never a re-login, never a new
question, and it is the same device-code choreography from step 2. Missing `repo` or `workflow`
fails the first push; missing `user` blocks [email verification](#email-verification) and
`vercel-provision`, so all three are topped up in one refresh. Wrong account active →
`gh auth switch`.

## Git identity

Set silently from what GitHub already knows — never ask a person their name through a machine they
just signed into. From `gh api user`:

- `user.name` ← `.name`, falling back to `.login`.
- `user.email` ← `.email`; when null — email set to private, or simply unreadable by this token —
  the noreply address `<id>+<login>@users.noreply.github.com`, which GitHub accepts for any
  account and keeps a private-email account's first push from a GH007 rejection.

Only unset values are written (`git config --global`). Values already set pass as-is — announced,
not corrected. A found email GitHub later refuses (GH007 on the first push) is a one-command
repair to the noreply address at that moment.

## Email verification

Confirmed from the API before anything is declared done, because the next skill in the chain
depends on it: `gh api user/emails --jq '.[] | select(.primary) | .verified'` must print `true`.

- 404, a scope error, or **empty output** — no primary entry visible — means the token cannot see
  emails, not that the email is unverified. gh's own default scopes do not include `user`, so an
  adopted login lands here routinely: `gh auth refresh -h github.com -s repo,workflow,user`
  ([Connect](#connect)), then re-read. That is a click, not a question, and a login this skill
  minted never needs it.
- `false` → Claude opens <https://github.com/settings/emails> and clicks **Resend verification
  email** (rung 1: the page opens pinned and the owner clicks it); the owner clicks the link in
  their inbox; re-read the API once.
- Still `false`, or no mail arriving → the FAIL line **in place of the done-line**, naming what it
  blocks: `FAIL — primary email not verified — owner clicks the link GitHub emailed;
  vercel-provision cannot start until then`. The rest of the [proof block](#proof-of-done) still
  prints, because auth and identity really are done. Saying so here beats failing halfway through
  the next skill.

## Proof of done

One compact block, every run, read fresh from the world:

- `gh auth status --active` — the account name, and the token's scopes, which must show `repo` and
  `workflow` (and `user`, which is what the next skill reads through).
- `git config --global user.name` / `user.email` — the values, and whether this run set them or
  found them.
- Primary email, from `gh api user/emails` — `verified: true`, or `verified: false` alongside the
  FAIL line below.
- Browser teardown, one line, per [the browser](#the-browser) — "connected to your own browser,
  nothing created" or the kit profile path and that it is gone.
- The closing line, exactly one of the two:
  - all five things done → "GitHub is done — account, CLI, git identity, verified email. Vercel
    can chain off this."
  - anything unfixed → `FAIL — <what> — <who acts next>`, **instead of** that done-line, never
    alongside it and never silently deferred. The rows above it still print: what is done is
    reported as done, and only the done-*line* is withheld.

## Not this skill

- Which browser, which profile, which driver, and the connection itself — `browser-connect`.
- Account hardening of any kind. This connector delivers account + access for today; hardening
  policy belongs to the app-building flow that consumes it, and nothing here asks about it.
- Vercel and Supabase sign-in — `vercel-provision` (which hard-requires this skill's proof of
  done) and `supabase-provision`.
- Creating repositories — `app-builder` owns repo creation (M2).
- CWK's `github-connector` — it mints a personal access token and registers an MCP server. The
  pack authenticates through `gh auth login` only; on a machine with both installed, "connect my
  GitHub" for workshop provisioning routes here.
