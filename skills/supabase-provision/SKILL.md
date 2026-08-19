---
name: supabase-provision
description: Provisions the Supabase third of the blessed path — account signed up via GitHub SSO (no separate password), organization created, supabase CLI logged in with its access token in the CLI's native store, all proven by a create/delete project smoke test that leaves nothing behind. Detect-before-create at every step; safe to re-run after any interruption. Use during workshop onboarding once the GitHub checks pass, or any time Supabase account/org/CLI state is unknown.
---

# supabase-provision

Gets one attendee from "no Supabase" to **account (GitHub SSO) + organization + authed CLI**, and
proves it with a real create/delete round-trip against the Supabase API — the Supabase link in
convention 7's chained identity (`CONVENTIONS.md`). Identity is GitHub SSO only: no Supabase
password is ever created, so there is nothing extra to protect. The org is where every future app
project lives (one project per app, convention 6); `app-builder` assumes it exists and never
re-negotiates it.

Every step opens with its detect and skips what already passes (M3 rule: detect from the world, no
state file — re-running is always safe). Credential entry runs under the hands-off window, and any
browser Claude drives dies with its profile, or the owner is told what is left — the contract in
[Consent and the credential window](#consent-and-the-credential-window) below (convention 7).

## Before this skill

The `GH-*` group must pass — SSO signs in *as* that GitHub account. Inside `app-foundation-setup`
that is already true by ordering; standalone, run the `GH-*` group from
[checks.md](../foundation-check/checks.md) first and stop while it fails (no GitHub account at
all is `github-provision`'s create path).

## Consent and the credential window

Before the first sign-in of a run, Claude says the consent lines — plain English, out loud, then
waits for the owner's go-ahead:

> - Your Supabase access token is minted and stored by the supabase CLI itself — Windows
>   Credential Manager here, the Keychain on a Mac, or, on a machine with no keyring for it to
>   reach, a file in the CLI's own folder — exactly as it would if you ran `supabase login` by
>   hand. What actually protects it is your Windows login — your macOS login on a Mac — and your
>   disk encryption. Where it is that fallback file, the CLI asks for owner-only permissions on it;
>   macOS and Linux honour that, Windows ignores it, and nothing here pretends otherwise.
> - I never see your password or MFA codes. While you type them I go hands-off completely — no
>   reads, no screenshots, no key presses — until you tell me you're done.
> - If I drive a browser for any step, it runs on its own throwaway profile, and I delete that
>   profile — cookies and sign-in sessions for GitHub, Vercel and Supabase alike — when
>   provisioning ends, and I check that it's gone. If anything on this machine holds that folder
>   open I'll tell you and show you exactly what to delete yourself, rather than pretend it's
>   gone. Your own browser is never touched.

**Said once per sitting, not once per skill.** Those lines belong to the first provisioner that
reaches a sign-in. If another provisioner already said them in this session — the workshop case,
where `app-foundation-setup` runs the three in order — don't recite them again. Say only what
changes here: the first bullet, where this skill's CLI keeps its token, and the third, whole — that
a browser driven for any step here runs on its own throwaway profile, that Claude deletes that
profile when provisioning ends and checks it is gone, that anything on this machine still holding
that folder open gets named out loud along with exactly what the owner must delete, and that the
owner's own browser is never touched. That third bullet is a change, not repetition: the
connectors that usually reach sign-ins first (`github-provision`, `vercel-provision`) ride the
owner's daily browser or a persistent kit profile, so what changes here is precisely that this
skill's driven browser is throwaway and deleted, and an owner told only afterwards that a folder
holding their live sign-in sits on their disk was never asked. All four of its promises
are said, the last one especially: hearing "I may drive a browser" straight after "every sign-in
happens in your own browser" raises the question of whose, and that promise is the answer. Then
check the owner is still happy to go ahead. The boundary promise and the credential window below
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

**Driven-browser teardown.** A browser Claude drives is launched on a dedicated automation profile
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

**1. Tooling — CLI-SUPABASE.** Detect and fix exactly as the registry says (fresh shell after
installs).

**2. Account + CLI auth — SB-AUTH.** Detect: `supabase projects list` exits 0.

- **Passes** → adopt. The account exists and the CLI is authed. Confirm with the owner that the
  account is their own — not an employee's, not shared (the GH-OWNER rule, applied to Supabase) —
  and ask the one-liner: "do you sign in to Supabase with GitHub?" (a password-based sign-in is
  off the blessed path — note it in the step-5 report; never create a duplicate account over it).
  Employee's or shared → treat as no account: run `supabase logout`, have the owner sign out of
  supabase.com as well as GitHub in the browser, then create fresh below. Go to step 3.
- **Fails** → `supabase login` (owner-in-loop) is both the signup and the auth step: it opens the
  browser to Supabase's sign-in page, and an owner with no account gets one the moment they first
  sign in with GitHub — there is no separate registration form on the blessed path. Give the
  owner the route before going hands-off: choose **Continue with GitHub**, authorize Supabase on
  the GitHub screen (first time only), click through any welcome step, and the token then hands
  itself back to the terminal. **Wrong-account-SSO trap:** before authorizing, the GitHub session
  in that browser must belong to the owner (the GH-AUTH active username); if it doesn't, sign out
  of GitHub (and supabase.com, if signed in) in the browser and go hands-off while the owner
  signs in as themselves.
- Owner lost in the browser → fall back to portal-driving (the xero-mcp-setup donor pattern):
  drive the same route click by click in a driven browser, under the credential-window contract
  above — hands-off while credentials are typed, teardown when provisioning ends.
- Re-detect: `supabase projects list` must exit 0 before step 3.

The token is minted and stored by the CLI's native storage mechanism — the OS keyring (Windows
Credential Manager / macOS Keychain) where available, its documented fallback file
(`~/.supabase/access-token`) otherwise — which is convention 7's rule as applied to each CLI's
native store; the real boundary is OS login + disk encryption. The detect is
`supabase projects list`; the token is never read, copied, or echoed.

**3. Organization — SB-ORG.** Detect: `supabase orgs list` shows at least one organization
(signup onboarding sometimes creates it — the detect decides, never assume). The fix is
owner-only, per the registry: the owner creates the organization at
<https://supabase.com/dashboard> → **New organization** — their business name, Free plan. An
owner comfortable in the terminal may instead run `supabase orgs create "<business name>"`
themselves; either way creating the org is the owner's act, not Claude's. Re-detect: the org
appears in `supabase orgs list`.

**4. Prove it — smoke test.** Run the platform script:
`pwsh scripts/smoke-test.ps1` (Windows — no `pwsh`?
`powershell -ExecutionPolicy Bypass -File scripts/smoke-test.ps1`) or
`bash scripts/smoke-test.sh` (macOS). It creates a throwaway project and deletes it again,
detect-before-create end to end: sweeps any `fsbp-smoke-*` leftover from an interrupted run,
refuses to create when the org already sits at the free-tier project cap, creates
`fsbp-smoke-<rand>` (region `ap-southeast-2`, Sydney — closest to the workshop room; override
with `-Region` / `--region`), verifies it is listed, deletes it, verifies it is gone.
`SMOKE PASS` and exit 0 is the acceptance; anything else is a failure to fix, not to talk around.
More than one org → pass `-OrgId` / `--org-id`. At the cap the only moves are the owner choosing
Supabase Pro or a different org — **never** delete an existing project to make room. (The install
channels ship the CLI's Bun implementation as `supabase`; pack scripts read its output with
`-o json` — never `--output-format json`, which wraps the payload in an envelope.)

**5. Report.** First the driven-browser teardown, if any browser was driven this run. Then one
table — CLI-SUPABASE, SB-AUTH, SB-ORG, SMOKE | PASS/FAIL | evidence | created or adopted — plus
one teardown line: profile deleted (with the path), teardown FAILED (with the path and what the
owner must delete by hand), or no browser driven. Anything still failing names who acts next.

All pass → Supabase provisioning is done — **unless the teardown line says FAILED**. A failed
teardown is not a provisioning failure: it is not one of the checks, it fails no row, it turns
nothing red, and the account, the org and the CLI really are set up. But it is not "done" either,
and "done" over a green table is exactly what gets nodded past in a workshop room. So while that
line stands, don't say the word — say what actually happened: the Supabase account, organization
and CLI are set up, **and** a folder holding the live sign-in sessions this run used — GitHub and
Supabase — is still on this machine at that path and has to be deleted before the owner leaves.

## Rules quoted from CONVENTIONS.md

- **Convention 7** — GitHub SSO chains identity; hands-off window during credential entry; driven
  browser profile deleted after provisioning; tokens live in each CLI's native store.
- **Convention 6, said up front, not discovered in production:** one Supabase project per app,
  and two free-tier cliffs. **Cliff 1 — project cap:** the free tier allows roughly **two active
  projects per organisation**, so one project per app means the **third app** triggers
  **Supabase Pro** — business use triggers it earlier, per convention 6's business-use trigger.
  Pro is **$25/mo plus usage-based compute** beyond the included quota — **never quote it as a
  flat $25**. The smoke test refuses to create at the cap for the same reason: that upgrade is
  the owner's decision, not a side effect. **Cliff 2 — auto-pause:**
  free projects pause after ~1 week idle and then return opaque 500s — the most likely
  post-workshop "my app broke" event; unpausing is one click in the dashboard.
- **Convention 3** — the database schema only ever changes from committed migrations. This skill
  touches no schema: the smoke project is created empty and deleted in the same run.

## Not this skill

- GitHub account, git identity, gh CLI — `github-provision`.
- Vercel account, CLI, GitHub app — `vercel-provision`.
- The full pre-flight doctor and PASS/FAIL banner — `foundation-check`.
- Running all provisioners to green in order — `app-foundation-setup`.
- An app's real Supabase project, schema, RLS, auth — `app-builder` and the M2 data+auth module
  own those; the smoke project here is a proof, deleted before this skill reports done.
- Supabase administration for developers — CWK's `supabase-admin`; on a machine with both packs
  installed, Supabase onboarding routes here, not there.
