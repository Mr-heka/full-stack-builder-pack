# Storage policies from migrations may be refused (supabase/supabase#41126)

**Status: verified NOT biting on-path — live run 2026-07-21: the
GitHub-linked deploy applied the template's `create_files_bucket` migration on a current
free-tier project and all four `create policy` statements landed (`pg_policies` count = 4).
Upstream, #41126 was closed 2025-12-29 as resolved — a transient ownership change that
self-resolved — and the fail-safe wrapper stays as cheap insurance anyway.**

Supabase's April 2025 permission change
([discussion #34270](https://github.com/supabase/supabase/discussions/34270)) says the migration
role can still `CREATE POLICY` on `storage.objects`. Issue
[supabase/supabase#41126](https://github.com/supabase/supabase/issues/41126) (Dec 2025) reported
the opposite on one project: `must be owner of table objects` from scripted migrations. The
thread tells the rest: the same statement succeeded over plain `psql` the same day, the
reporter's own scripts worked again two days later with nothing changed on his end, and the
issue was closed 2025-12-29 as resolved — a transient platform-side blip, not a standing rule.

Had a refusal like that been biting persistently on current free-tier projects, there would be
**no on-path way to create storage RLS policies** — every channel that still worked (dashboard
SQL editor, direct `psql`) is manual SQL outside a committed migration, exactly what
CONVENTIONS.md #3 forbids. That would need a doctrine carve-out, not a workaround.

## What the pack does about it

- The template's `files`-bucket migration wraps its four `create policy` statements in a
  `do $$ ... exception when insufficient_privilege` block, so the app's **first push can never go
  red because of this** — the deploy-proof migration stays green either way. If skipped, it
  raises a warning and the private bucket stays locked (nobody can read or write it) until
  policies land by another route.
- A live acceptance run (GitHub-linked deploy on a test app) settled which
  world we're in: after the deploy, `select policyname from pg_policies where tablename =
  'objects'` returned all four policies — the migration role can still create storage policies
  on a current free-tier project.

## If a future deploy skips the policies

Fallback candidates, in order: declarative buckets via `config.toml` `[storage.buckets]`
(CLI v2 config-as-code — the GitHub integration deploys storage buckets), or a documented
one-time dashboard step with an explicit CONVENTIONS.md carve-out for `storage.*` policies.
The 2026-07-21 live run means neither is needed today — revisit only if the fail-safe's
skip warning ever fires on a real deploy.
