# Stray sweep — finding every place an app lives

The pain this fixes: apps deployed to **six different places** with no continuous deploy. This
file is how `deploy-doctor` finds all six and walks them back to one. It runs inside the doctor's
audit (read-only) and guided-fix (click-to-change) phases, under SKILL.md's doctrine — including
the never-auto-delete list, which binds every move here.

## The inventory — four ledgers plus the owner

Cross-match four independent views of the world; disagreement between them IS the findings list:

| Ledger | Read with |
|---|---|
| Local app directories | Scan `~/apps` (the pack's base directory), plus any location the owner names — a directory is app-shaped when it carries the template's markers (`app.config.ts`, `CONVENTIONS.md`) or the owner claims it |
| GitHub repos | `gh repo list <owner> --json name,pushedAt --limit 200` — `gh` returns only 30 by default, and a ledger that stopped at 30 reports "no strays" for repos it never looked at. Come back at the limit → raise it and re-run. Pack-born repos carry `CONVENTIONS.md` at root: confirm per candidate with `gh api repos/<owner>/<repo>/contents/CONVENTIONS.md` → 200 |
| Vercel projects | `vercel api "/v9/projects?limit=100"` — one ledger, one paging scheme: it returns every project with its `link` (which repo, if any), and `pagination.next` is followed until the list ends. A page that comes back at the limit with `pagination.next` still set means more projects exist, and a sweep that stopped there cannot support "no strays". Then `/v9/projects/<name>/domains` per project (custom domains — the never-auto-delete guard reads this). PowerShell on Windows (drift-checks.md rules) |
| Supabase projects | `supabase projects list -o json` (never `--output-format json` — drift-checks.md rules) |

**Say what the sweep could see.** Every ledger above has a bound, and "no strays found" is only ever
a claim about what was listed. The report says which ledgers were read, how many each returned, and
whether any came back at its limit — and if one did, it says the sweep is incomplete until it is
re-run wider, rather than printing a clean bill of health.

Then the **owner interview** closes what no ledger can see — CLI and drag-and-drop deploys leave
no repo artifact, and they are the most common stray:

> "Any live URL you've ever shared — text, socials, the business site — that isn't on this list?
> Anywhere else this app has ever been put live, even once, even 'just to try it'?"

Every URL the owner names gets attributed (below) or stays on the report as **unattributed live
URL — FLAG** until it is.

## Stray classes

| Stray | Detected by | Class |
|---|---|---|
| Second Vercel project on one repo (convention 1) | Two projects whose `link` points at the same repo | guided-fix |
| Unlinked near-twin | A project with no `link` whose deployments serve the same app — resemblance, not evidence | FLAG until the owner attributes it |
| Unlinked / local-only directory | App-shaped local dir with no origin remote, unpushed commits, or no Vercel project behind it | guided-fix |
| Supabase project no app points at, or a second one for an app that already has one (convention 6) | In the ledger, a `<ref>` matched against no app's `NEXT_PUBLIC_SUPABASE_URL` and no repo's `supabase/config.toml` | **guidance only** — it is a database |
| CD off / rolled back | DD-CD | guided-fix (that check's fix) |
| Env drift | DD-ENV | guided-fix (that check's fix) |
| Foreign host | Artifacts + authed-CLI checks below | **FLAG-only** |
| Unattributed live URL | Owner interview | **FLAG-only** until attributed |

## Foreign hosts — detect wide, touch nothing

Three detection layers, in order. A foreign CLI is **never installed or authed to hunt** — layer 2
uses only what already works on the machine.

**1. Repo artifacts** — in every repo and local app dir:

| Host | Markers |
|---|---|
| Netlify | `netlify.toml`, `.netlify/` |
| Render | `render.yaml` |
| Cloudflare Pages/Workers | `wrangler.toml`, `wrangler.json`/`wrangler.jsonc` |
| GitHub Pages | `CNAME` file, a `gh-pages` branch, Pages enabled (`gh api repos/<owner>/<repo>/pages` → 200) |
| Railway | `railway.json`, `railway.toml` |
| Any host via CI | `.github/workflows/*.yml` steps that deploy — grep for `netlify`, `cloudflare/pages-action`, `wrangler-action`, `railway`, `gh-pages`, `peaceiris/actions-gh-pages` |

**2. Authed-CLI checks** — wherever a foreign CLI is already present and signed in
(`netlify status`, `wrangler whoami`, `railway whoami`, `render services` — each only if
`--version` already works): list that platform's sites/projects and match names against the
inventory.

**3. Owner interview** — the unattributable-URL question above; a live URL serving the app's
content with no artifact and no CLI trail is attributed by asking, not guessing.

**FLAG-only means:** the finding names the host, the evidence, and what the blessed path already
covers, and the report says plainly — *"this copy is outside the pack's one path; nothing here
will touch it."* The doctor performs **no foreign-platform surgery** — no foreign deploys, no
foreign deletions, no foreign settings changes. When the owner wants a flagged foreign copy gone,
the doctor supplies the plain-English steps for the owner's own hands, after the decommission
protocol below clears it. A foreign-host *artifact file* sitting in a blessed repo (a stray
`netlify.toml`) is offered for deletion as a normal committed change **only after the foreign
copy it feeds is confirmed retired** — those artifacts usually mean the foreign host builds from
this repo, so pushing the deletion earlier rebuilds or breaks a live foreign site: foreign
surgery by git proxy. Until then the artifact stays part of the flag.

## Decommission protocol — one at a time, from strength

Order enforced (SKILL.md run step 4): **the blessed path is live and its production URL returned
200 to a `HEAD` request this run** before the first stray offer is made. Then, per stray, one at a
time:

1. **Attribute it.** What is it, which app is it a copy of, what serves it, does anything point at
   it (custom domain, links the owner shared)?
2. **Data-parity confirm — before any decommission offer.** The offer may not be made until the
   owner confirms, explicitly, one of: **the blessed app holds this stray's data** (checked
   against the stray's own store where one exists — row counts, newest records), or **no data
   exists there worth keeping**. No confirm, no offer — the stray stays flagged instead.
3. **Offer the retirement, scoped by the never-auto-delete list** (SKILL.md doctrine). Every
   retirement here is **irreversible**, so it is re-confirmed by name immediately before it runs,
   whatever the owner said to the table earlier (SKILL.md doctrine rule 2):
   - A second Vercel project serving no traffic and holding no custom domain → on the owner's OK,
     `vercel project rm <name>` (auto-on-OK) — but only when it is **positively attributed**: its
     `link` points at the blessed repo, or the owner looks at its URL and its env-var names and says
     out loud that they do not want it. A project matched to an app by resemblance alone is never
     removed by the doctor; it is named on the report with its URL and the owner decides. Before the
     OK, say what goes with it: the project, its deployment history and its environment variables,
     permanently, and any DNS record pointed here from outside stops resolving.
   - An unlinked local-only directory → never deleted; adopted instead: on the owner's OK, walk it
     onto the blessed path (repo + Vercel link + push — `app-builder`'s step-3 moves) or leave it
     archived where it is, named on the report as local-only by choice.
   - A Supabase project nothing points at → **guidance only**, always: it holds data, and it is the
     cheapest thing on this list to be wrong about. Name it, say what it is costing — on the free
     tier it occupies one of the ~2 project slots per organisation, which is what makes the next app
     trigger Supabase Pro (convention 6) — and give the dashboard steps. The owner's hands, never
     the doctor's.
   - Anything serving traffic, any custom domain or DNS record, any database, any foreign-host
     site → **guidance only**, always: the exact dashboard steps, the owner's hands. This holds
     even after every confirm in this protocol.
4. **Re-verify the blessed path** after each retirement (`HEAD` request, 200 again — the retirement
   must not have been load-bearing), then move to the next stray.

The end state of a full consolidation is the report showing one line per app: one repo, one Vercel
project, one Supabase project, CD live, no flags — the blessed path, with nothing else answering for
it **in anything the sweep could see**. Say it that way. The ledgers and the owner interview are
what the doctor has; a copy on a platform nobody named and no artifact betrays is outside them, and
claiming otherwise is the one promise this skill must never make.
