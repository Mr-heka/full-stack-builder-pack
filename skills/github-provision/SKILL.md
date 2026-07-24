---
name: github-provision
description: Get one hardened GitHub account onto this machine for the full-stack builder pack — adopt the owner's existing account or create one, install git and the gh CLI, authenticate into gh's own token storage, and verify business email + 2FA + recovery codes. Use when foundation-check fails a git/gh/GH-* check, when an attendee needs GitHub set up, or standalone before vercel-provision and supabase-provision. Detect-before-create; safe to re-run.
---

# github-provision

The account this skill delivers is the identity for everything after it: Vercel and Supabase sign
in with GitHub (`CONVENTIONS.md` convention 7), so one GitHub account gets adopted — or created —
once, hardened, and never duplicated. Done means: git + gh installed; the active account is one
the owner controls, signed in with a token gh stores itself; and convention 7's three hard
criteria verified — business email, 2FA via the API, recovery codes saved somewhere the owner
names.

## Detect, then route

Open with this skill's group of the detect registry —
[checks.md](../foundation-check/checks.md): CLI-GIT, CLI-GH, GIT-\*, GH-\*, per the mapping
table at the top of that file — under that file's rules. What passes is skipped. No state file:
re-running this skill only ever touches what is broken right now.

Then route on one question to the owner — **"do you have a GitHub account of your own?"**

| The owner's situation | Path |
|---|---|
| Has their own account — signed in here or not | **Adopt** it. Never create a duplicate. |
| The only account around is an employee's or shared | **Create fresh** — the one exception to adopt |
| No account | **Create** |

Adopt is the default on purpose: two accounts on one laptop is the wrong-account-SSO trap —
Vercel and Supabase chain to whichever GitHub session the browser happens to hold, and the
attendee finds out weeks later that their app lives under the wrong identity.

## Install

Fix CLI-GIT and CLI-GH per the registry (winget / brew), re-detect in a fresh shell. Set GIT-NAME
and GIT-EMAIL from the owner's answers — the same business email the account will use.

## Consent and the credential window

Before the first sign-in of a run, Claude says the consent lines — plain English, out loud, then
waits for the owner's go-ahead:

> - Your GitHub sign-in token is stored by the gh CLI itself — Windows Credential Manager here,
>   the Keychain on a Mac, or, where the CLI can't reach a credential store, a plain-text file in
>   gh's own config folder — the same place `gh auth login` puts it when you run it by hand. gh
>   tells us which: `gh auth status` names the store it used, and I'll read that back to you. What
>   actually protects it is your Windows login — your macOS login on a Mac — and your disk
>   encryption.
> - I never see your password, MFA codes, or recovery codes. While you type them I go hands-off
>   completely — no reads, no screenshots, no key presses — until you tell me you're done.
> - Every sign-in happens in your own browser. I open a page — meaning I hand the address to
>   *your* default browser, never to one I control — or I hand you the link. I never drive a
>   browser in this skill, so there is no automation session holding your credentials.

Read that location back as soon as gh has one to give — never a guess, and once per run. Where
GH-AUTH failed and a fresh login follows, it is the account line of the `gh auth status` re-detect
that login's fix already requires; where GH-AUTH passed on entry and Authenticate is skipped, it
is the account line that detect has already printed.

**Said once per sitting, not once per skill.** Those lines belong to the first provisioner that
reaches a sign-in — usually this one, since the SSO chain starts here. If another provisioner
already said them in this session — the workshop case, where `app-foundation-setup` runs the three
in order — don't recite them again. Say only what changes here: the first bullet, where this
skill's CLI keeps its token, and the third, that this skill drives no browser at all. Then check
the owner is still happy to go ahead. The boundary promise and the credential window below are not
re-recited — they were said once and they hold for the whole sitting. Consent recited three times
stops being heard the first time. Whichever way the lines are said, say only the platform in front
of you: they carry Windows and macOS so one file serves both, and reading both aloud is not the
intent.

**"Open the page" means the owner's own browser.** Everywhere this skill says Claude opens a page
— the device-code page, the sign-out page, the owner-only settings links, the signup form — it
means handing the address to the machine's default browser and stopping there. Never a
browser-automation tool, never an automation profile, not once. This is the whole reason the skill
carries no teardown contract: it tears nothing down because it drives nothing. Satisfying an "open
the page" step with browser automation would drive a browser holding the owner's GitHub session on
a profile nothing in this file is written to delete, and would void that exemption silently. If a
step seems to need a driven browser, it belongs to `vercel-provision` or `supabase-provision`,
which carry the teardown contract — not here.

**The hands-off window.** It opens the moment Claude hands the owner a sign-in of any kind — a
login command started, a link given, a page opened in their browser, an OAuth authorize screen or
a device-code screen reached — and it opens *without waiting to see what the screen says*. In this
skill the sign-in is always in the owner's own browser, which Claude by design cannot see, so
there is never a screen to read first. An unexpected re-auth mid-run is the same case: an expired
session turns an authorize screen into a full password and MFA prompt with no warning, so the
window opens when the screen is handed over, not when its contents are known. If Claude cannot see
the owner's screen, that is a reason to be hands-off, not a reason to check. Claude says
"hands-off — tell me when you're done" and stops there — that message ends Claude's turn. From
that message until the owner says they're done, Claude makes no further tool calls — no reads of
any kind, no screenshots, no keystrokes. Whatever was already running — a login command, or
nothing at all while the owner works in their own browser — keeps running untouched. Only the
owner saying they're done closes the window — never a timeout, never peeking to check progress.
Ending the turn is what makes that real: the announce and the owner's "done" bracket the window in
the transcript, and the empty stretch between them is the evidence: verifiable, not promised.

## Authenticate

CLI first, browser as fallback:

1. `gh auth login --web` (owner-in-loop). gh prints a one-time code and opens the browser; the
   hands-off window holds while the owner signs in and clears any 2FA challenge, until the owner
   says they're done.
2. No browser opened, or the flow stalled? The owner opens <https://github.com/login/device>
   themselves — any browser — and enters the code gh printed. Same end state.

Either way, the token lands wherever gh keeps it: its native credential store (Windows Credential
Manager; macOS Keychain), or a plain-text file in gh's own config folder where the CLI can't reach
a credential store. Nothing is minted by hand: no personal access tokens, nothing for the owner to
copy or for Claude to see.

If `gh auth status` shows the wrong account active, `gh auth switch` — don't re-login. On the
create-fresh exception, Claude runs `gh auth logout` for the employee's or shared account, and
the owner signs out of github.com in the browser themselves — Claude opens the page at most,
hands off from there — before the new account signs in, so SSO can only chain the right identity.

## Adopt

Work the remaining GH-* failures in registry order. GH-2FA, GH-EMAIL, and GH-RECOVERY are
owner-only: open the page for the owner — or give the link — with the plain-English words, the
owner acts, then re-detect: GH-2FA via the API, GH-EMAIL via the API plus the owner's fresh
confirmation, GH-RECOVERY by asking again. Never verify by reading the settings page.

- **2FA** (GH-2FA): enrollment belongs in the day-before pre-flight email, done at home with the
  authenticator walkthrough. An adopt-cohort owner without 2FA does enrollment now at
  <https://github.com/settings/security> — Claude cannot do this step for them.
- **Business email** (GH-EMAIL): the owner adds their business address at
  <https://github.com/settings/emails>, clicks the verification email, and sets it primary. A
  personal address already on the account can stay — primary is what must be the business one.
- **Recovery codes** (GH-RECOVERY): <https://github.com/settings/auth/recovery-codes>; the owner
  saves them and names where, out loud. Claude never sees the codes.

## Create

Account creation and 2FA enrollment belong in the pre-flight email — at home, phone verification
included. The live create path is the no-show fallback, and it carries one hard rule: each signup
runs over the attendee's own phone tethering, staggered across attendees — never several fresh
signups behind one venue IP, which flags accounts at creation.

The owner signs up at <https://github.com/signup> with the business email and completes phone
verification themselves; Claude opens the page, then hands off for the whole form. Then continue
exactly as adopt: authenticate, 2FA, recovery codes.

## Pass bar

Re-run the full group. This skill passes only when every check passes — convention 7's criteria
are acceptance, not advice:

- **GH-2FA** — the API returns `true`. Empty output means missing token scope first, not a
  verdict: apply the registry's scope note and re-detect — still empty after the refresh is a
  FAIL ("could not verify"), never a pass.
- **GH-EMAIL** — primary email is a business address the owner confirms they control. A 404 from
  the detect is the same scope case — same refresh, same re-detect, same FAIL if it persists.
- **GH-RECOVERY** — the owner names where the codes are saved.

Anything still failing is reported as FAIL with who has to act — never silently deferred.

## Not this skill

- Verifying the whole machine across all three platforms — `foundation-check`; this skill runs
  only its own registry group.
- Vercel and Supabase sign-in — `vercel-provision` and `supabase-provision`, which SSO with the
  account this skill hardens.
- Running the full onboarding to green — `app-foundation-setup` orchestrates the provisioners.
- Creating repositories — `app-builder` owns repo creation (M2).
- CWK's `github-connector` — it mints a personal access token and registers an MCP server. The
  pack authenticates through `gh auth login` only, leaving the token wherever gh itself stores it;
  on a machine with both installed, "connect my GitHub" for workshop provisioning routes here.
