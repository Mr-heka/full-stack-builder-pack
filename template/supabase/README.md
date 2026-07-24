# supabase/

The database side of push = deploy (CONVENTIONS.md #3): migration files committed to
`supabase/migrations/` are applied to the production database automatically on push to `main`,
via Supabase's GitHub-linked deploy. Available on the free plan. The schema never changes any
other way — no dashboard SQL, no CLI pushes.

## Wire it up (once per app)

1. Supabase dashboard → your project → **Project Settings → Integrations → GitHub**.
2. Connect this repo. **Working directory** = `.` (the `supabase/` folder is at the repo root).
3. Enable **Deploy to production** for branch `main`.

From then on, every push to `main` applies any new files in `migrations/` in filename order.

Also set, under **Auth → URL Configuration**: Site URL = your live Vercel URL, and add
`http://localhost:3000` to Redirect URLs (for local dev sign-in).

## Writing migrations

- One change per file, named `<YYYYMMDDHHmmss>_<what_it_does>.sql` (UTC timestamp — the order
  they run in).
- **Additive** changes (new tables, new nullable columns, new policies) just get committed and
  pushed. Anything not provably additive is treated as destructive; on a populated table an
  index build locks writes — gate it like a destructive change.
- **Destructive** changes (dropping/renaming anything, narrowing types, deleting rows) happen
  only after a plain-English confirmation of exactly what's lost and an automatic export of the
  affected tables — ask Claude to make the change and it follows that path. Backups land in
  `exports/` (git-ignored).
- After the push, verify the migration actually applied (the app's features touching the new
  schema work) — a green Vercel deploy alone says nothing about the database.

There is no `config.toml` here on purpose: migration deploys don't need it, and the less this
folder carries, the less can drift.

## What ships in the template

- `migrations/20260721013000_create_files_bucket.sql` — the storage pattern: one private
  `files` bucket only signed-in users can access (owner-only, until customer login is
  explicitly added). It also proves the GitHub-linked deploy on the app's first push.

Auth wiring lives in the app itself: `lib/supabase/` (clients + session refresh),
`app/login/` (owner-only magic link), `app/auth/confirm/` (link landing), `app/owner/`
(the signed-in area). The one address that can sign in is `ownerEmail` in `app.config.ts` —
it must be the email the owner uses for Supabase itself, because Supabase's built-in mailer
only delivers to the project org's own members (2 emails/hour). Any other sign-in audience
needs custom SMTP first. Before setting up custom SMTP, disable public signups (Supabase
dashboard → Auth → "Allow new users to sign up") — the files-bucket policies admit any
signed-in user, not just the owner.
