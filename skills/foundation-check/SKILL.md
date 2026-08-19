---
name: foundation-check
description: Workshop pre-flight doctor for the full-stack builder pack. Verifies GitHub, Vercel, and Supabase accounts, their CLIs, git identity, and the browser-connect driver in one run — PASS/FAIL table, fixes what it can, ends with a full-screen banner. Use before provisioning or building, after any interruption, or any time machine state is unknown; safe to re-run.
---

# foundation-check

One run answers one question: **is this machine ready to build on the blessed path?** The path is
GitHub + Vercel + Supabase with GitHub SSO chaining all identity (`STACK.md`); the account
hardening rules it verifies are `CONVENTIONS.md` convention 7. This skill is the resume engine for
onboarding — every fix ends by re-detecting, so re-running after any interruption picks up exactly
where the world actually is.

## Run

1. **Detect.** Run every check in [checks.md](checks.md), in order, under that file's rules.
   Collect each verdict plus the evidence found (version, username, email — whatever the detect
   printed).
2. **Report.** Print one table: `Check | Status | Found | Fix`. Status is PASS or FAIL only. Found
   is the evidence. Fix names what will happen next for each FAIL — or who has to act, for
   owner-only checks.
3. **Fix.** Work the failures in registry order, honoring each check's fix class. During any
   owner-in-loop credential entry, hands off completely until the owner says they're done.
4. **Re-check.** Re-detect everything that failed (fresh shell after installs). Repeat fix →
   re-check until all pass or every remaining failure is one the owner can't — or has chosen not
   to — act on right now.
5. **Banner.** Fill the terminal. All pass →
   `pwsh scripts/banner.ps1 -Result PASS -Detail "<total>/<total> CHECKS PASSED"` (Windows — no
   `pwsh`? `powershell -ExecutionPolicy Bypass -File scripts/banner.ps1`, same arguments) or
   `bash scripts/banner.sh PASS "<total>/<total> CHECKS PASSED"` (macOS). Anything still failing →
   the same script with `FAIL` and `"<n> OF <total> CHECKS FAILED"`, after the final table — the
   banner fills the screen, so the table stays one scroll up. The banner needs a real terminal to
   fill; if it runs where none renders, give the owner the exact command to run in their own
   terminal (in Claude Code, the `!` prefix).

No state file, ever. The world is the state.

## Not this skill

- Creating accounts, orgs, or projects — `github-provision`, `vercel-provision`, and
  `supabase-provision` own creation; they open with their group of this skill's detect checks
  (mapping at the top of `checks.md`).
- Establishing the browser driver — `browser-connect` owns the BROWSER fix: the pick, the pin,
  the extension choreography.
- Running the whole onboarding to green — `app-foundation-setup` orchestrates check → fix →
  re-check across the provisioners.
- Anything after an app exists — post-deploy drift is `deploy-doctor`; building is `app-builder`.

## Standalone use

[PASTE-PROMPT.md](PASTE-PROMPT.md) is the self-contained copy of this skill for the workshop
pre-flight email — it works on a laptop that has never seen this pack, which is exactly why it
carries the 15 account/CLI checks and not BROWSER: that one needs the installed pack.
