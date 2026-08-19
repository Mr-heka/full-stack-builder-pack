---
name: browser-connect
description: The real-browser driver — connects agent skills to the owner's everyday browser instead of a browser the agent launches. Use whenever a skill hands the owner a URL to open, needs to read signed-in session state, or needs a driven browser for a web flow. Three rungs — pinned handoff links (zero setup), Playwright MCP extension mode (mainline driven browser), kit-owned Playwright profile (fallback). Detects the daily browser and profile deterministically; safe to re-run.
---

# browser-connect

> **Vendored copy** — canonical source is the stand-alone
> [`selrai-company/browser-connect`](https://github.com/selrai-company/browser-connect) repo,
> pinned here at commit `ecd46b8`. Edit there and re-vendor; the pack never fetches it live,
> so a workshop install needs no second repo.

The owner's everyday browser is where their accounts already live — signed-in sessions,
remembered devices, a browser fingerprint no bot-detector flags. This skill is the one way any
consumer skill reaches that browser, at three rungs of capability. What every rung buys:
**detection-first** — an existing signed-in account discovered in the browser is a PASS to
announce ("already signed in as X — skipping signup"), never contamination — and **no
misroutes**: every URL handed to the owner lands in the browser and profile they actually use.

A browser the agent *launches* is a different animal: `navigator.webdriver` is true there, and
sites that score automation (GitHub's OAuth Authorize page, among others) hard-block it. A driver
that *attaches* to the owner's normally-launched browser — rung 2 — carries none of that:
`navigator.webdriver` is false, verified live. That is why extension mode is the mainline driver
and the launched-profile rung is the fallback, not the default.

## The ladder

| Rung | What | Setup | Drives? |
|---|---|---|---|
| 1. Pinned handoff links | Open URLs for the owner in their daily browser + profile | none | no — owner clicks |
| 2. Extension mode (mainline) | Playwright MCP attached to the owner's real running browser | one-time, ~2 clicks | yes — reads free, clicks choreographed |
| 3. Kit-owned profile (fallback) | Playwright launches its own profile | none | yes — with launched-browser limits |

Rung 1 is always on — it needs nothing and every consumer skill uses it for every handoff.
Rung 2 is offered when the daily browser is Chrome or Edge; the owner's ~2 clicks buy session
detection and driven flows in their real browser. Rung 3 is the answer when the daily browser
is not Chrome/Edge, or the owner declines the extension.

## Detection

Run the platform script — `bash scripts/detect.sh` (macOS) or `pwsh scripts/detect.ps1`
(Windows; written to the same spec but **untested until a Windows QA pass** — treat its output
as unverified). Read-only, silent, prints one JSON object:

- **Daily browser** = the OS default handler for `https` — macOS LaunchServices, Windows
  `UrlAssociations\https\UserChoice`. `extension_capable` is true for Chrome/Edge.
- **Profiles**, ranked by the size of each profile's `History` file. Accumulated history
  identifies where the person lives. **Never rank by recency** — `active_time` picks whichever
  window had focus last, and lost to a rarely-used backup window in live testing.
- **Pick** = the history-size winner, with the top-two margin. Single profile → use it
  silently. Multiple → auto-pick and **announce it** ("using your 'Person 1' profile —
  owner@example.com — say the word to switch") with a one-word override. Ask first only when
  `ask` is true — the top two within ~2× of each other.
- **Pin** = the contents of `~/.fsbp/browser.json`, if one exists (below).

Chromium profile directory names (`Default`, `Profile 1`, `Profile 2`, …) are assigned at
creation and never renamed, renumbered, or reordered — deletions leave gaps — so a pinned
`--profile-directory` value stays valid for the life of the profile.

## The pin — `~/.fsbp/browser.json`

Once a profile is settled — auto-pick accepted, or the owner names one — store it:

```json
{ "browser": "chrome", "profileDirectory": "Profile 1", "email": "owner@example.com",
  "mode": "extension", "source": "auto", "pinnedAt": "2026-08-19" }
```

`source` is `auto` or `override`; `mode` is `extension` or `kit-profile`. An **explicit
override beats auto-detect, always**: the owner saying "use my other profile" (list the
profiles from the detect output, let them choose) writes `source: override`, and no later
auto-pick displaces it. This file is the justified exception to detect-never-store: an
override is the owner's stated choice and is not re-derivable from the world. Everything else
in the pin is re-checked against a fresh detect each run — a pinned profile that no longer
exists in the detect output means re-detect, re-announce, re-pin.

## Rung 1 — pinned handoff links

Every URL handed to the owner opens by **naming the detected browser binary and pinned
profile** — never the OS default handler. A running Chrome routes default-handler opens to the
most-recently-focused window's profile, which is exactly how wrong-profile misroutes happen.

- macOS: `"<binary from detect>" --profile-directory="<pinned dir>" "<url>"` — forwards
  correctly to a running instance. Chromium browser with `binary: null` in the detect output
  (an install the standard paths don't cover):
  `open -b <bundle id> --args --profile-directory="<pinned dir>" "<url>"` — still named, still
  pinned.
- Windows: `Start-Process "<binary>" -ArgumentList '--profile-directory="<pinned dir>"', '"<url>"'`.
- Non-Chromium daily browser (Safari, Firefox, …): no profile routing exists to get wrong —
  open by naming the browser (`open -a Safari "<url>"`), still never the bare default handler.

Bare `open <url>` / `start <url>` / `xdg-open <url>` on a handoff link is banned in every
consumer skill.

## Rung 2 — extension mode, the mainline driver

Playwright MCP's `--extension` mode drives the owner's real, already-running browser through
the **Playwright MCP Bridge** extension. Verified live: `navigator.webdriver` is false, session
detection reads work on signed-in sites, and token-authed reconnects are silent and
restart-safe.

**Onboarding choreography** (one-time, absorbed into the consumer kit's install flow):

1. Detect + pin per above; announce the pick.
2. Write the MCP config: register a `playwright` server running
   `npx @playwright/mcp@latest --extension` in the consumer's MCP config (for Claude Code:
   `claude mcp add --scope user playwright -- npx @playwright/mcp@latest --extension`).
3. Open the Chrome Web Store page for **Playwright MCP Bridge** as a rung-1 pinned link — the
   pinning is what guarantees the extension installs into the pinned profile, not whichever
   window was focused.
4. The owner clicks **Add to Chrome** → **Add extension** — their two clicks — then restarts
   the agent session so the new MCP server loads. Fold that restart into whatever restart the
   install flow already has; the consumer's re-entry prompt resumes here.
5. Connect: on first use the owner approves the connection in the extension — or, once, opens
   the extension, copies its token, and pastes it into chat; store it as
   `PLAYWRIGHT_MCP_EXTENSION_TOKEN` on the MCP server config. With the token every connect is
   silent — no picker page, nothing to misroute — and a fresh server process reconnects
   without another approval.

**The extension is per-profile.** Switching the pin to another profile re-runs steps 3–5
there — two clicks, not a rebuild.

**Conduct in the owner's browser.** The sessions the driver can now see are the owner's real
ones, so the reads are free and the clicks are choreographed:

- Session-detection reads (who is signed in, what a settings page shows) are read-only and
  always announced — that is detection-first working.
- Any click that grants, authorizes, pays, or deletes stays the owner's click. Attaching to
  the real browser makes an agent *capable* of an OAuth Authorize click — keeping it human is
  a consent choice, made deliberately, not a technical limit. Reaching a live Authorize page
  on a signed-in account can auto-complete a previously-authorized grant the moment it loads —
  treat navigation to such pages as itself a consented step.
- The hands-off window (below) binds exactly as it does everywhere else.

## Rung 3 — kit-owned profile fallback

No Chrome/Edge, or the owner declines the extension: Playwright launches its own browser on a
**kit-owned profile** — never the owner's real profile. Launched-browser limits apply
(`navigator.webdriver` is true; automation-scored pages like third-party OAuth Authorize
hard-block, so those clicks are the owner's in their own browser via rung-1 links). Whether
that profile persists per-owner (session persistence as a feature on a single-user machine) or
is created fresh per run and deleted is the consumer kit's teardown contract to set; fresh +
delete is the conservative default, and multi-account operator machines always get fresh +
delete.

## The hands-off window

Unchanged from every credential-handling doctrine this skill serves, and mode-independent: the
moment any credential, MFA, or authorize screen is handed to the owner — link opened, command
started, driven page reached — the agent makes **zero tool calls** of any kind until the owner
says they're done. No reads, no screenshots, no keystrokes, in the owner's browser least of
all. Only the owner closes the window; never a timeout, never peeking.

## Teardown, by mode

- **Extension mode: disconnect, delete nothing.** It is the owner's browser — profile, cookies
  and sessions are theirs, and were never the agent's to create. Teardown is ending the MCP
  session; there is no folder to remove, and the report line is "connected to your own
  browser — nothing created, nothing to delete".
- **Kit-owned profile: the consumer kit's teardown contract governs** — under fresh-per-run,
  close the browser, delete the profile directory, confirm it is gone, and report the path;
  never report a teardown that did not happen.

## Not this skill

- What to do on any given site — consumer skills own their flows; this skill owns which
  browser, which profile, which driver, and the conduct rules above.
- Credential storage — each CLI's native store, per the consumer kit's doctrine.
- Any always-on browser MCP already configured on a machine for other work — this skill
  configures its own connection and touches nothing else's.
