---
name: vercel-provision
description: Provisions the Vercel half of the blessed path — account signs in with GitHub SSO (created accounts get no separate password), vercel CLI logged in with its token in the CLI's native auth file, and the Vercel GitHub app connected so push = deploy works from the first app. Detect-before-create at every step; safe to re-run after any interruption. Use during workshop onboarding once the GitHub checks pass, or any time Vercel account/CLI/app state is unknown.
---

# vercel-provision

Gets one attendee from "no Vercel" to **account (GitHub SSO) + authed CLI + connected GitHub app** —
the Vercel link in convention 7's chained identity (`CONVENTIONS.md`). Identity is GitHub SSO:
created accounts are born with no Vercel password — nothing extra to protect — and adopted
accounts get GitHub sign-in connected, though an existing password survives adoption. The GitHub
app connect is what makes convention 3's push = deploy real; `app-builder` assumes it, with one
sanctioned inline recovery — re-widening the installation to **All repositories** when a new
repo turns out to be invisible to the app (the same blessed scope set here); anything beyond
that routes back to this skill.

Every step opens with its detect and skips what already passes (the registry's rule: detect from
the world, no state file — re-running is always safe). Browser work routes through
`browser-connect`: handoff links open pinned to the owner's daily profile, and a driven browser
is the owner's own connected one (extension mode, the mainline) or a kit-owned fallback profile
that dies with the run. Credential entry runs under the hands-off window — the contract in
[Consent and the credential window](#consent-and-the-credential-window) below (convention 7).

## Before this skill

The `GH-*` group must pass — SSO signs in *as* that GitHub account. Inside `app-foundation-setup`
that is already true by ordering; standalone, run the `GH-*` group from
[checks.md](../foundation-check/checks.md) first and stop while it fails (no GitHub account at
all is `github-provision`'s create path).

## Consent and the credential window

Before the first sign-in of a run, Claude says the consent lines — plain English, out loud, then
waits for the owner's go-ahead:

> - Your Vercel sign-in token is stored by the vercel CLI itself, in its own auth file on this
>   machine — the same place `vercel login` puts it when you run it by hand. What actually
>   protects that file is your Windows login — your macOS login on a Mac — and your disk
>   encryption. The CLI asks for owner-only permissions on the file; macOS and Linux honour that,
>   Windows ignores it, and nothing here pretends otherwise.
> - I never see your password or MFA codes. While you type them I go hands-off completely — no
>   reads, no screenshots, no key presses — until you tell me you're done.
> - If I drive a browser for any step, it's normally your own everyday one, through the
>   extension you approved at setup — I read pages and fill forms only as the steps spell out,
>   any click that grants access stays yours, and when we're done I just disconnect: I create
>   nothing in your browser and delete nothing in it. If instead we're on the fallback — no
>   Chrome or Edge, or you said no to the extension — I drive a separate browser on its own
>   throwaway profile, and I delete that profile — cookies and sign-in sessions for GitHub,
>   Vercel and Supabase alike — when provisioning ends, and I check that it's gone. If anything
>   on this machine holds that folder open I'll tell you and show you exactly what to delete
>   yourself, rather than pretend it's gone.

**Said once per sitting, not once per skill.** Those lines belong to the first provisioner that
reaches a sign-in. If another provisioner already said them in this session — the workshop case,
where `app-foundation-setup` runs the three in order — don't recite them again. Say only what
changes here: the first bullet, where this skill's CLI keeps its token, and the third, whole —
which browser a driven step uses in this sitting's mode: the owner's own connected one, where
clicks that grant access stay theirs and teardown is a disconnect that deletes nothing, or the
fallback's throwaway profile, deleted when provisioning ends, checked gone, with anything still
holding it — and what the owner must delete themselves — named out loud. That third bullet is a
change, not repetition: `github-provision` — normally the first to reach a sign-in — promises it
never clicks or types in a browser, so what changes here is precisely that this skill does, and
whose browser that is — the question "I may drive a browser" raises the moment it is said — is
exactly what the bullet answers. Then check the owner is still happy to go ahead. The boundary
promise and the credential window below
are not re-recited — they were said once and they hold for the whole sitting. Consent recited three
times stops being heard the first time. Whichever way the lines are said, say only the platform in
front of you: they carry Windows and macOS so one file serves both, and reading both aloud is not
the intent.

**The hands-off window.** It opens the moment Claude hands the owner a sign-in of any kind — a
login command started, a link given, a page opened, an OAuth authorize screen or a device-code
screen reached — and it opens *without waiting to see what the screen says*. An unexpected re-auth
mid-run is the same case: an expired session turns an authorize screen into a full password and MFA
prompt with no warning, so the window opens when the screen is handed over, not when its contents
are known. If Claude cannot see the owner's screen, that is a reason to be hands-off, not a reason
to check. Claude says "hands-off — tell me when you're done" and stops there — that message ends
Claude's turn. From that message until the owner says they're done, Claude makes no further tool
calls — no reads of any kind, no screenshots, no keystrokes, no commands to a driven browser.
Whatever was already running — a login command, a driven browser left on the sign-in page, or
nothing at all while the owner works in their own browser — keeps running untouched. Only the
owner saying they're done closes the window — never a timeout, never peeking to check progress.
Ending the turn is what makes that real: the announce and the owner's "done" bracket the window in
the transcript, and the empty stretch between them is the evidence: verifiable, not promised.

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

## Steps

Registry checks are quoted from [checks.md](../foundation-check/checks.md) — this skill opens
with its group per the mapping there, under that file's rules and fix classes.

**1. Tooling — CLI-NODE, CLI-VERCEL.** Detect and fix exactly as the registry says (fresh shell
after installs).

**2. Account + CLI auth — VC-AUTH.** Detect: `vercel whoami`.

**Wrong-account-SSO trap — every Continue with GitHub below, and step 3's app-install page:**
before authorizing or installing, confirm the GitHub session in that browser belongs to the owner
(the GH-AUTH active username); if it doesn't, sign out of GitHub in the browser and go hands-off
while the owner signs in as themselves. In extension mode that confirmation is one read of the
connected browser — the signed-in github.com username against GH-AUTH's active account — and the
pinned profile makes the wrong-browser variant of this trap structurally impossible. A wrong
session signs into — or silently creates — the wrong Vercel account, and `vercel whoami` still
passes.

- **Passes** → adopt. The account exists and the CLI is authed. Two owner attestations, fresh
  every run: the account is their own — not an employee's, not shared (the GH-OWNER rule, applied
  to Vercel) — **and** it signs in with GitHub as the same account GH-AUTH shows. Signs in any
  other way — email + password only, a different GitHub account connected, or another provider
  (GitLab/Bitbucket) → the owner signs in to vercel.com the way that works today and connects the
  GH-AUTH GitHub account at Account Settings → Authentication before step 3 (the **Yes**-branch
  move; the CLI token already held stays valid).
  Employee's or shared → `vercel logout` first, so the cached wrong-account token can't
  false-pass the re-detect, then take the **Fails** ladder — the owner may still have an account
  of their own to adopt.
- **Fails** → ask the owner: "do you already have a Vercel account of your own?"
  - **Yes** → adopt, never duplicate. Account already signs in with GitHub as the same account
    GH-AUTH shows → owner-in-loop: `vercel login`, owner picks **Continue with GitHub** (the
    registry fix). Any other sign-in — email + password, a different GitHub account connected, or
    another provider (GitLab/Bitbucket) → connect the GH-AUTH GitHub account **before** any SSO
    attempt: the owner signs in to vercel.com the way that account signs in today (browser,
    owner-in-loop), connects GitHub sign-in at Account Settings → Authentication from inside that
    session, then runs `vercel login` → Continue with GitHub. SSO tried first would miss the
    account and silently mint a fresh one under the GitHub identity — the exact duplicate adopt
    exists to prevent.
  - **No** → sign-up in the driven browser, per the mode above. Extension mode opens with its
    own detect: load <https://vercel.com/dashboard> in the connected browser — landing on the
    dashboard means an account already exists ("you're already signed in to Vercel as X" —
    announce it, take the **Yes** branch), a redirect to `/login` means genuinely none. Then
    open <https://vercel.com/signup>, choose **Hobby**, and the **Continue with GitHub** click
    is the owner's — it grants access, so it stays human — with hands-off from the moment any
    sign-in or authorize screen is up, until they say they're done. On the fallback profile:
    same route, and the GitHub sign-in and Authorize clicks are the owner's there too (a
    launched browser is automation-scored — GitHub disables the Authorize button for it
    regardless). Then `vercel login` (owner-in-loop) so the CLI mints and stores its token.
  - Re-detect: `vercel whoami` must print a username before step 3.

The token lands in the vercel CLI's own auth file (convention 7's handling rule: each official
CLI's native store — on Windows the CLI's data dir is `%APPDATA%\xdg.data\com.vercel.cli`). That
file is the CLI's default store, not its only one — recent versions can be pointed at an OS keyring
instead — so describe it as where the CLI puts it, never as the only place it could be. The detect
is `vercel whoami`; the file is never read or copied.

**3. GitHub app connect — VC-APP.** This check lives here, not in the registry: the registry takes
only silent no-input commands, and the app's only trustworthy detect is a browser read
(`gh api user/installations` returns 403 for OAuth tokens — verified, no CLI detect exists).

Detect: open <https://github.com/apps/vercel> as the owner's GitHub account — in extension mode
this is a read-only look through the connected browser, Claude's to run and announce; otherwise
it is the owner's look, link plus the words. The install button
reading **Install** means the app is not installed. **Configure** alone is not yet a PASS — the
button reflects any installation this user can reach and says nothing about scope. One more click:
open the configuration and confirm the owner's own account is an install target with **All
repositories**. Both true → PASS. Installed only elsewhere (an org, another account) → run the fix
below; owner's account at narrower scope → owner-only — the owner widens it to All repositories
on that same page, then re-detect.

Fix: installing the app is a grant, so the **Install** click follows the mode's actor rule. In
extension mode Claude opens the page in the connected browser and the owner clicks — choose their
own account, scope **All repositories**, confirm — the consent choice, kept human. On the
fallback, auto only while a driven session from this run already holds the owner's GitHub sign-in
(from the signup branch above); owner-only otherwise — link plus the plain-English words. Either
way GitHub hands back to vercel.com to finish the connection. All repositories is the blessed
choice: every future app repo (one repo
per app, convention 1) deploys with no per-app browser detour.
Re-detect: the detect above passes — **Configure**, owner's account, **All repositories** — and
Vercel's import screen lists the owner's GitHub repos.

**4. Report.** First the driven-browser teardown, if any browser was driven this run. Then one
table — CLI-NODE, CLI-VERCEL, VC-AUTH, VC-APP | PASS/FAIL | evidence | created or adopted — plus
one teardown line: connected to your own browser — nothing created, nothing to delete (extension
mode), profile deleted (with the path), teardown FAILED (with the path and what the owner must
delete by hand), or no browser driven. Anything still failing names who acts next.

All pass → Vercel provisioning is done — **unless the teardown line says FAILED**. A failed
teardown is not a provisioning failure: it is not one of the checks, it fails no row, it turns
nothing red, and the account, the CLI and the GitHub app really are set up. But it is not "done"
either, and "done" over a green table is exactly what gets nodded past in a workshop room. So while
that line stands, don't say the word — say what actually happened: the Vercel account, CLI and
GitHub app are set up, **and** a folder holding the live sign-in sessions this run used — GitHub
and Vercel — is still on this machine at that path and has to be deleted before the owner leaves.

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
- GitHub account, git identity, gh CLI — `github-provision`.
- Supabase account, org, CLI — `supabase-provision`.
- The full pre-flight doctor and PASS/FAIL banner — `foundation-check`.
- Running all provisioners to green in order — `app-foundation-setup`.
- Creating a Vercel project, linking a repo, deploying — `app-builder`.
- CWK's `deploy-to-vercel` — its later paths link and deploy from the CLI. The pack deploys only
  by pushing (convention 3); on a machine with both packs installed, Vercel onboarding for the
  workshop routes here.
