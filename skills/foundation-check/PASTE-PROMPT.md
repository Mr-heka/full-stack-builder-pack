# Workshop pre-flight paste-prompt

Everything inside the fence below goes into the day-before pre-flight email (and the morning-of
chase message). The attendee opens Claude Code on their own laptop and pastes the whole block —
nothing else installed, no pack required. Safe to paste again at any point; it only ever fixes
what is actually broken right now.

Canonical source for the checks: [checks.md](checks.md). This prompt embeds the registry's 15
account/CLI checks; the sixteenth, BROWSER, stays out on purpose — it needs the installed pack
(the vendored `browser-connect` scripts and the MCP config), so it runs at pack install and in
`foundation-check`, never in the day-before email.

````text
You are running a workshop pre-flight check. Verify this machine is ready to build and deploy a
full-stack app on GitHub + Vercel + Supabase, fix what you can, and end with a full-screen verdict
banner. Work through the checks below in order. Rules:

- Detect from the world only — no state file, and never skip a detect because of an earlier run.
- Never apply a fix whose detect passes. Every fix ends by re-running its detect (installs need a
  fresh shell for PATH).
- A detect command that prompts or hangs counts as FAIL — kill it and move on. Questions the
  checks below tell you to ask me are expected — ask them fresh every run, never cache my answers.
- While I type any password, MFA code, or browser login, hands off completely: start the login
  command where I can type into it — if your shell can't take my keyboard input, give me the exact
  command to run in my own terminal (the ! prefix here) — then wait for me to say I'm done. Never
  read, echo, or ask for credentials, recovery codes, or MFA codes.

CHECKS (ID | detect | pass when | fix):
1. CLI-GIT | git --version | prints a version | install: winget install --id Git.Git -e (Windows) / brew install git (mac)
2. CLI-NODE | node --version | v20+ | install: winget install --id OpenJS.NodeJS.LTS -e / brew install node (not node@NN — keg-only, never lands on PATH)
3. CLI-GH | gh --version | prints a version | install: winget install --id GitHub.cli -e / brew install gh
4. CLI-VERCEL | vercel --version | prints a version | install: npm install -g vercel (after CLI-NODE)
5. CLI-SUPABASE | supabase --version | prints a version | install (Windows, in PowerShell): scoop bucket add supabase https://github.com/supabase/scoop-bucket.git; scoop install supabase (no Scoop? irm get.scoop.sh | iex first) / mac: brew install supabase/tap/supabase
6. GIT-NAME | git config --global user.name | non-empty | ask me my name, then set it
7. GIT-EMAIL | git config --global user.email | non-empty AND I confirm it's a business email I control | ask me, then set it
8. GH-AUTH | gh auth status | logged in to github.com, active account | gh auth login --web (hands-off while I sign in)
9. GH-OWNER | active username from GH-AUTH — if GH-AUTH failed, skip the question and mark FAIL (no account to confirm) | I confirm the account is mine — not an employee's, not shared | wrong account: gh auth login / gh auth switch; none at all: tell me to flag it to the instructor
10. GH-2FA | gh api user --jq .two_factor_authentication | outputs true | I enable it at https://github.com/settings/security — you cannot do this for me
11. GH-EMAIL | gh api user/emails --jq '.[] | select(.primary).email' | primary email is a business address I control — ask me, don't judge the domain yourself | I fix it at https://github.com/settings/emails
12. GH-RECOVERY | ask me: "where are your GitHub recovery codes saved?" — if GH-2FA failed, skip the question and mark FAIL (codes only exist once 2FA is on) | I name a location | https://github.com/settings/auth/recovery-codes — never ask to see the codes
13. VC-AUTH | vercel whoami | prints a username | vercel login → I pick "Continue with GitHub" (hands-off)
14. SB-AUTH | supabase projects list | exits 0 (empty table still passes) | supabase login → I sign in with GitHub in the browser (hands-off)
15. SB-ORG | supabase orgs list | at least one organization | I create one at https://supabase.com/dashboard → New organization

Scope note for 10 and 11: empty output on 10 or a 404 on 11 means the gh token is missing the
"user" scope, not that the check failed — run gh auth refresh -h github.com -s user (hands-off
while I approve in the browser), then re-run both. Still empty after that → FAIL "could not verify".
If gh auth status shows several accounts, every GH check runs against the active one.

Then:
1. Print one table — Check | Status | Found | Fix — with PASS or FAIL for all 15, the evidence you
   saw, and what happens next for each FAIL.
2. Work the failures in order. Re-detect, fix, re-check until everything passes or the only
   failures left need me to act somewhere you can't, or are ones I've told you to skip for now.
3. Finish with a banner that fills the entire terminal so an instructor can read it from the front
   of the room: green background with giant block letters PASS if all 15 passed, red background
   with giant block letters FAIL otherwise, plus a count line ("15/15 CHECKS PASSED" or
   "2 OF 15 CHECKS FAILED"). On Windows write a short PowerShell script to a temp file and run it
   with powershell -ExecutionPolicy Bypass -File (Write-Host full-width lines with
   -BackgroundColor Green/Red, block letters made of █, centered, padded to the full window height
   and width); on mac do the same in bash with ANSI codes (\033[42;30m / \033[41;97m). If anything
   failed, print the final table just before the banner — the banner fills the screen, so the
   table sits one scroll up.
````
