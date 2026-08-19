# skills/

One folder per skill, each with its own `SKILL.md`. All ten skills —
`browser-connect`, `foundation-check`, `github-provision`, `vercel-provision`,
`supabase-provision`, `app-foundation-setup`, `app-builder`, `deploy-doctor`,
`app-iterate` and `app-status` — are live, grouped by the milestone that
shipped them:

- **Browser driver** — `browser-connect`: a vendored, pinned copy of the stand-alone
  `browser-connect` repo (its SKILL.md names the pinned commit — edit upstream and re-vendor,
  never here). Every pack skill routes its handoff links through it; the provisioners route
  their driven-browser steps through it too.
- **M3 provisioners** — `foundation-check`, `github-provision`, `vercel-provision`, `supabase-provision`, `app-foundation-setup`
- **M2 builders** — `app-builder`, `app-iterate`, `app-status`
- **M4 doctor** — `deploy-doctor`

Shared rules: detect before create; every skill quotes `CONVENTIONS.md`; sibling skills are named in each SKILL.md's NOT-for lines.

Shared modules live in `../modules/` — `modules/data-auth/` owns schema/auth/storage
doctrine + the Docker-free pre-migration export script; `app-builder` and `app-iterate` follow it
for anything database-shaped.
