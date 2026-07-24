# skills/

One folder per skill, each with its own `SKILL.md`. `foundation-check`,
`github-provision`, `vercel-provision`, `supabase-provision`,
`app-foundation-setup`, `app-builder`, `deploy-doctor`,
`app-iterate` and `app-status` are live; the rest are placeholders until
their milestone ships:

- **M3 provisioners** — `foundation-check`, `github-provision`, `vercel-provision`, `supabase-provision`, `app-foundation-setup`
- **M2 builders** — `app-builder`, `app-iterate`, `app-status`
- **M4 doctor** — `deploy-doctor`

Shared rules: detect before create; every skill quotes `CONVENTIONS.md`; sibling skills are named in each SKILL.md's NOT-for lines.

Shared modules live in `../modules/` — `modules/data-auth/` owns schema/auth/storage
doctrine + the Docker-free pre-migration export script; `app-builder` and `app-iterate` follow it
for anything database-shaped.
