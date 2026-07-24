---
name: app-foundation-setup
description: Workshop-entry orchestrator for the full-stack builder pack — runs foundation-check, routes every failure to its provisioner (github-provision, then vercel-provision and supabase-provision) and re-checks until the machine is all green, 15 registry checks plus the Vercel GitHub app. No state file; re-pasting the entry prompt after any interruption is the resume procedure. The owner types only passwords, MFA codes, and quick confirmations. Use as the first prompt of the workshop, or any time onboarding stopped partway.
---

# app-foundation-setup

One prompt takes a machine from unknown to **ready to build**: every registry check green, the
Vercel GitHub app connected, the full-screen PASS banner on screen — the state `app-builder`
assumes and never re-negotiates. The pack README's Install prompt is the pasteable form: it
clones the pack, lands here, and this skill runs the rest.

This skill owns no fixes and no registry check — `foundation-check` owns detection and the
banner, the three provisioners own their fixes. What it owns is orchestration: check → route
failures to their owners, in order → re-check until PASS — plus the two proofs the registry
can't see (step 3).

## The loop

1. **Check.** Run `foundation-check`'s detect and report — all 15 checks of
   [checks.md](../foundation-check/checks.md), one `Check | Status | Found | Fix` table — and
   stop it there: inside this skill, fixing belongs to the provisioners below, so the Fix column
   names the provisioner that will act.

2. **Route.** Any failure in a group → run that group's provisioner, whole: it re-detects for
   itself, skips what passes, and carries steps the registry can't see. The order is the SSO
   chain — GitHub first, then the two that sign in with it:

   | Any of these failing | Run |
   |---|---|
   | CLI-GIT, CLI-GH, GIT-\*, GH-\* | `github-provision` |
   | CLI-NODE, CLI-VERCEL, VC-\* | `vercel-provision` |
   | CLI-SUPABASE, SB-\* | `supabase-provision` |

   The groups quote the mapping table at the top of
   [checks.md](../foundation-check/checks.md) — that table is canonical.

   While the GH-\* group still fails — any check in it, owner blocked or deferring a fix — the
   other two provisioners don't run. Two reasons, either one enough on its own: SSO signs in *as*
   that GitHub account, so a wrong identity propagates into both; and convention 7 makes business
   email, 2FA and saved recovery codes hard acceptance criteria for provisioning, not advice, so
   chaining Vercel and Supabase onto an unhardened account is the thing that convention exists to
   prevent. Report and stop.

3. **The proofs the registry can't see.** A green registry is not quite done — two proofs live
   outside it, each with its own detect and its own owner:

   - **The Vercel GitHub app (VC-APP)** — lives in `vercel-provision` step 3; no silent detect
     exists, and the detect there is a browser read of <https://github.com/apps/vercel> signed in
     as the owner. If `vercel-provision` ran this loop, the gate came with it. If its group was
     already green in step 1 — say a run interrupted between CLI login and app connect — run
     `vercel-provision` anyway: its detect-skip walks past the green checks and lands on step 3,
     which owns that detect under its own consent lines, credential window and teardown. Never
     run that detect from here — it belongs to the skill that owns the fix behind it, and a proof
     read by one owner and fixed by another is how a half-installed app gets reported green. In
     that already-green path no driven session from this run holds the owner's GitHub sign-in, so
     the actor rule `vercel-provision` step 3 already states for its fix — owner-only otherwise —
     is the one its detect runs under too: Claude gives the owner the link and names the two
     things to read back (the button says Configure rather than Install, and the owner's own
     account is listed as an install target with All repositories), the owner reads them back,
     and the owner's own browser is never driven. `app-builder` assumes this app is installed;
     here is the last place that is assured.
   - **A finished smoke test** — an interrupted `supabase-provision` smoke run leaves its tell:
     a `fsbp-smoke-*` project in `supabase projects list`. Read that list here by name — SB-AUTH
     passes on the command exiting 0, so its evidence cell may never have kept the project names.
     A Supabase group green in step 1 with that tell present is not proven — run
     `supabase-provision`; its smoke step sweeps the leftover and completes the proof. Left alone
     it eats one of the org's two free-tier project slots.

4. **Re-check, then banner.** Re-run step 1 with fresh detects — detect and report only, the same
   stop. Loop until either every check passes and the step-3 proofs hold — `foundation-check`'s
   green PASS banner ends the run — or nobody can clear what is left: the owner can't act, or has
   chosen not to, or a fix that is Claude's to run has failed the same way twice with the same
   evidence. Two identical failures in a row is the signal to stop trying, not to try harder.
   Then the red FAIL banner, final table one scroll up naming who acts next and what was tried.

   The banner is `foundation-check`'s step 5 and its script, reached directly: that skill's own
   fix and re-check steps stay skipped for the whole of this orchestration — the provisioners own
   every fix, and running them from two owners is how an account gets signed in the wrong way
   round. The baseline total is 16: the 15 registry checks plus VC-APP, which is a row in the final
   table on every run, passing or failing, and is counted on both sides. That is the total the
   clean run this skill exists to reach arrives at — `16/16 CHECKS PASSED` — and fifteen green
   registry rows under a failing VC-APP reads `1 OF 16 CHECKS FAILED`. The only thing that moves
   the total is the other step-3 proof. The finished smoke test is not a row when it holds or was
   never in play — it is proven inside `supabase-provision`'s own report table — so it never
   inflates a passing run; but a smoke proof that is in play and still failing is appended to the
   final table as its own row and lifts the total along with the failure count, so fifteen green
   registry rows and a green VC-APP under a failing smoke proof reads `1 OF 17 CHECKS FAILED`. An
   appended row moves both sides together, so a red banner never shows a zero failure count, and
   the proofs step 4's exit condition waits on are exactly the rows the count is taken over. The
   banner never states a total the table above it contradicts.

## Resume is re-paste

No state file, ever — the world is the state, and `foundation-check` is the resume engine. Every
step opens with a fresh detect, so an interrupt anywhere — closed laptop, dropped wifi, a login
abandoned mid-browser — has one recovery: paste the same entry prompt again. The next check finds
exactly what survived; only what is broken right now gets touched. One deliberate consequence: a
Supabase group green in step 1 adopts without re-running `supabase-provision`'s smoke test — that
proof belongs to the provisioner's own runs, an interrupted smoke run is still caught by its
leftover tell (step 3), and `app-builder` re-checks project count before it ever creates
anything.

## The owner's part

The owner types passwords and MFA codes when a sign-in page opens, answers the attestation
questions fresh every run, and acts on owner-only links. Everything else is Claude's. During any
credential entry, hands off completely under the provisioners' own contract — the "Consent and the
credential window" section of whichever provisioner is running (convention 7). The announce ends
Claude's turn; only the owner saying they're done reopens it. This skill does not restate that
contract in shorter words.

**The consent lines are said once per sitting, not once per provisioner.** Running three
provisioners in order is the case that would otherwise read the same promises to one attendee three
times over, and consent recited three times stops being heard the first time. So: the first
provisioner to reach a sign-in says its consent block whole. Each one after says only what changes
— where *its own* CLI keeps its token, and, for a provisioner that may drive a browser, the
throwaway-profile promise that goes with it: deleted when provisioning ends, checked gone, the
owner told exactly what to delete if anything still holds it open, and the owner's own browser
never touched — and checks the owner is still happy to go ahead. Saying that second thing is not
repetition of the first block but the honest difference from it: `github-provision` promises it
never drives a browser, so a provisioner that may drive one is changing the promise the owner
already heard. The boundary promise and the credential window are not re-recited; they were said
once and they hold for the whole sitting, across all three. That rule is each provisioner's own,
written into its "Said once per sitting" paragraph; this skill only supplies what the provisioner
cannot know on its own — whether it is the first to reach a sign-in in this session. Track that,
and tell it. What is never in play is skipping the lines entirely: a sitting where no provisioner
said them whole is a sitting where the owner never gave consent.

Before the banner, account for every browser profile driven during this run. Each provisioner that
drove one tears it down and reports one of three lines — profile deleted with the path, teardown
FAILED with the path and what the owner must delete by hand, or no browser driven; carry that line
through verbatim rather than restating it. A teardown that failed is not a reason to withhold the
banner and never a reason to claim it succeeded: it is a report line, not a check — not one of the
16, no effect on the banner's colour, no hold on the banner either way. Machine readiness and
browser-profile cleanup are different questions; the banner counts the checks and the proofs step 4
waits on, and a browser profile is neither, so step 4's exit condition stays the only rule that
decides it — unlike a failing smoke proof, which is a readiness failure and does become a counted
row. What a FAILED line does require is that it be answered to the owner after the banner — the
banner fills the screen, so anything said before it scrolls out of sight. It also requires the same
restraint the provisioner already showed: the provisioner that reported a FAILED teardown declines
to call its own half "done" while that line stands, and this skill says nothing over the top of it
that a listener would hear as done. The banner stays green and stays what it says — the 16 checks
passed, the machine is ready to build — and the sentence after it says the other true thing about
that folder, which is one of two things depending on whether it is still there. Still there — the
ordinary case, and the one the FAILED line was written for: a folder holding a live sign-in session
is on this machine, at that path, and has to be deleted before the owner leaves, named in full
along with what they must delete. Already gone, because a later provisioner's pre-open sweep
removed it once the process holding it let go: say that instead — the folder reported FAILED has
since been cleaned up and there is nothing left for them to do. Check which before speaking; never
send the owner to a path that is no longer there, and never let a folder that is still there go
unsaid.

## Not this skill

- The checks, the report table, the banner — `foundation-check`; its
  [PASTE-PROMPT.md](../foundation-check/PASTE-PROMPT.md) is the day-before pre-flight email, a
  separate artifact from the workshop entry prompt in the pack README.
- Fixing anything — `github-provision`, `vercel-provision`, `supabase-provision` own every fix,
  routing decision (adopt vs create), and proof in their scope.
- Building the first app — `app-builder`; this skill's PASS banner is its precondition.
- Anything after an app exists — `deploy-doctor`.
