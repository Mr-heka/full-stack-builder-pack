# Detect-check registry

The reusable detect module for the M3 onboarding skills — 15 checks. This file is canonical:
[PASTE-PROMPT.md](PASTE-PROMPT.md) embeds a standalone copy of the registry, regenerated in the
same commit as any change here. `foundation-check` runs every check; each provisioner opens with
its own group as its detect-before-create step:

| Skill | Opens with |
|---|---|
| `github-provision` | CLI-GIT, CLI-GH, GIT-\*, GH-\* |
| `vercel-provision` | CLI-NODE, CLI-VERCEL, VC-\* |
| `supabase-provision` | CLI-SUPABASE, SB-\* |

The `vercel-provision` and `supabase-provision` groups assume the `GH-*` group already passes —
their auth fixes sign in with GitHub (SSO). `app-foundation-setup` runs the groups in order; a
provisioner running standalone runs the `GH-*` group first.

## Rules

- **Detect from the world, never from a state file.** A check's verdict comes from running its
  detect command right now. Never skip a detect because of a previous run's result.
- **A fix is never applied when its detect passes.** Re-running the whole registry is always safe.
- **Every detect command must complete without input.** A command that prompts or hangs is a FAIL,
  not a wait.
- **Owner attestations are detects too.** GH-OWNER, GH-RECOVERY, and the business-email
  confirmations in GIT-EMAIL and GH-EMAIL come from asking the owner, fresh every run — the
  owner's answer is the world; never cache it.
- **Fresh shell after installs.** A CLI installed this run is invisible to the current shell's PATH;
  re-run its detect in a new shell.
- **Fix classes.** `auto` — Claude completes it directly (it may ask the owner a question first).
  `owner-in-loop` — start the command, then hands off completely until the owner says they're done
  (`CONVENTIONS.md` convention 7: no reads during credential entry; Claude never sees passwords,
  MFA codes, or recovery codes). These logins are interactive — they run where the owner can type
  (in Claude Code, the owner runs the command with the `!` prefix), never in a shell the owner
  can't reach. `owner-only` — give the link and the plain-English words; the owner acts, then
  re-detect.

## Tooling

| ID | Detect | PASS when | Fix |
|---|---|---|---|
| CLI-GIT | `git --version` | prints a version | auto — Windows `winget install --id Git.Git -e`; macOS `brew install git` |
| CLI-NODE | `node --version` | v20 or higher | auto — Windows `winget install --id OpenJS.NodeJS.LTS -e`; macOS `brew install node` (not a versioned `node@NN` keg — those are keg-only and never land on PATH) |
| CLI-GH | `gh --version` | prints a version | auto — Windows `winget install --id GitHub.cli -e`; macOS `brew install gh` |
| CLI-VERCEL | `vercel --version` | prints a version | auto — `npm install -g vercel` (needs CLI-NODE) |
| CLI-SUPABASE | `supabase --version` | prints a version | auto — Windows, in PowerShell: `scoop bucket add supabase https://github.com/supabase/scoop-bucket.git; scoop install supabase` (no Scoop? `irm get.scoop.sh \| iex` first); macOS `brew install supabase/tap/supabase` |

## Git identity

| ID | Detect | PASS when | Fix |
|---|---|---|---|
| GIT-NAME | `git config --global user.name` | non-empty | auto — ask the owner their name, then `git config --global user.name "<name>"` |
| GIT-EMAIL | `git config --global user.email` | non-empty **and** the owner confirms it is a business email they control (convention 7) | auto — ask, then `git config --global user.email "<email>"` |

## GitHub account

| ID | Detect | PASS when | Fix |
|---|---|---|---|
| GH-AUTH | `gh auth status` | logged in to github.com with an active account | owner-in-loop — `gh auth login --web` |
| GH-OWNER | active account username from GH-AUTH output — while GH-AUTH fails, skip the question and mark FAIL (no account to confirm) | owner confirms the account is their own — not an employee's, not shared (adopt the owner's existing account, never create a duplicate) | owner-only — log in with the right account (`gh auth login`, or `gh auth switch` if it is already on the machine); no owned account at all is `github-provision`'s create path |
| GH-2FA | `gh api user --jq .two_factor_authentication` | outputs `true` | owner-only — enable 2FA at <https://github.com/settings/security> (the pre-flight email walks through authenticator setup) |
| GH-EMAIL | `gh api user/emails --jq '.[] \| select(.primary).email'` | primary email is a business address the owner confirms they control | owner-only — add and set primary at <https://github.com/settings/emails> |
| GH-RECOVERY | ask the owner: "where are your GitHub recovery codes saved?" — while GH-2FA fails, skip the question and mark FAIL (codes only exist once 2FA is on) | the owner names a location out loud | owner-only — <https://github.com/settings/auth/recovery-codes>; Claude never sees the codes |

**Scope note (verified behavior).** The default `gh` token (scopes `gist, read:org, repo, workflow`)
returns *empty* for the GH-2FA field and *404* for GH-EMAIL. That means missing scope, not missing
2FA: run `gh auth refresh -h github.com -s user` (owner-in-loop — browser approval), then re-run
both detects. Still empty after refresh → mark the check FAIL with "could not verify".

**Multiple accounts.** `gh auth status` can list several; every GH-\* check runs against the
*active* one. Wrong one active → `gh auth switch`, re-detect.

## Vercel account

| ID | Detect | PASS when | Fix |
|---|---|---|---|
| VC-AUTH | `vercel whoami` | prints a username | owner-in-loop — `vercel login`, choose **Continue with GitHub** (SSO, convention 7) |

## Supabase account

| ID | Detect | PASS when | Fix |
|---|---|---|---|
| SB-AUTH | `supabase projects list` | exits 0 (an empty project table still passes) | owner-in-loop — `supabase login`, sign in with GitHub in the browser |
| SB-ORG | `supabase orgs list` | at least one organization | owner-only — create one at <https://supabase.com/dashboard> → New organization (full setup is `supabase-provision`'s job) |
