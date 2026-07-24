# Data + auth module (M2 #13)

The pack's one way of doing schema, auth, and storage. `app-builder` and `app-iterate` follow this
module whenever an app touches the database; the matching code ships inside the pack's `template/`
(`lib/supabase/`, `app/login/`, `app/auth/`, `app/owner/`, `supabase/`). Doctrine source:
`CONVENTIONS.md` #3 (push = deploy, committed migrations) and #4 (destructive-migration safety).

## Migrations — the only way schema changes

Schema changes are `.sql` files in `supabase/migrations/`, named `<YYYYMMDDHHmmss>_<slug>.sql`
(UTC timestamp — order is the filename). Supabase's GitHub-linked deploy applies them on push to
`main`. No dashboard SQL, no CLI push: the repo is the schema's source of truth.

**The deploy connection** (once per app, in the Supabase dashboard): Project Settings →
Integrations → GitHub → connect the repo, Working directory `.`, enable **Deploy to
production** on `main`. Free-plan feature — Supabase's branching doc: "You can deploy directly
from GitHub on any plan"; only *preview* branches need Pro. `config.toml` is not required for
migration deploys, so the template's `supabase/` skeleton deliberately ships without one.

### Additive — apply silently

New tables, new nullable columns, new policies: write the migration, commit, push. No ceremony.
New indexes count as additive on empty or small tables; on a populated table an index build
locks writes — gate it like a destructive change. **Anything not provably additive is treated
as destructive** (CONVENTIONS.md #4). Verify post-push that the migration actually applied
(below) — "done" is never just URL 200.

### Destructive — export + confirm, then push

Dropping or renaming anything, type narrowing, `DELETE`/`TRUNCATE` of rows: two
steps happen **before** the push, because the push is what applies the migration. The export
runs first — it supplies the row counts the confirm names.

1. **Automatic Docker-free export of every affected table:**

   ```sh
   # run from the app repo; the pack's README install puts the script here
   SUPABASE_SECRET_KEY=sb_secret_... node ~/.claude/skills/full-stack-builder-pack/modules/data-auth/scripts/export-tables.mjs customers
   ```

   `scripts/export-tables.mjs` (this module) talks directly to the project's REST API and writes
   `exports/<timestamp>_pre-migration/<table>.csv` + `.sql`. The secret key comes from the
   Supabase dashboard (Project Settings → API keys) and is passed as an env var for that one
   command — the owner supplies it at that moment (pastes it when asked, or sets it in their
   own terminal). It is not one of the app's Vercel env vars: never committed, never in the
   repo or `.env.local` (the script deliberately ignores it there). `exports/` is git-ignored.

   **Never `supabase db dump`** — it shells out to a containerized pg_dump; attendee laptops do
   not get Docker Desktop. If the export fails, the migration does not get pushed.

2. **Plain-English confirm naming exactly what's lost.** Not "run destructive migration?" —
   name the table, the column, the row count, and what the business loses. Pattern:

   > This change deletes the **phone** column from **customers** — all **214** saved phone
   > numbers will be gone. The app keeps working; the numbers don't come back. A backup of
   > customers is already saved in `exports/` either way. Type **yes** to go ahead.

   The row count comes from the export (it prints per-table counts). No confirm, no push.

### Recovery — honest scope

- **Code**: Vercel one-click rollback (CONVENTIONS.md #4). Instant, no git knowledge — and a
  stopgap: it reaches one step back, and auto-deploy stays off until the rollback is undone.
  Always do #4's follow-through (fix or revert commit pushed to `main`, **and** Undo Rollback)
  so push = deploy resumes.
- **Data**: Claude-assisted restore from the pre-migration export. The `.sql` file carries the
  rows and an approximate column layout; a post-drop restore needs schema surgery (recreate the
  table/column first, then replay inserts). Say so up front — there is no data undo button.

### Verify post-push

A pushed migration is applied when the change is visible through the REST API (e.g. the new
column appears in `GET /rest/v1/` OpenAPI output, or a probe query succeeds) — check that, not
just the live URL. Applied-vs-committed parity over time is `deploy-doctor`'s drift check (M4).

## Auth — owner-only magic link, and only that in v1

One sign-in method: a magic link emailed to **exactly one address** — `ownerEmail` in
`app.config.ts`. No passwords. The gate is structural and sits at **two** points, because
Supabase's OTP endpoint is publicly callable with the (public) anon key regardless of what the
app's own form allows:

1. **Send gate** — the login server action (`app/login/actions.ts`) refuses any other address
   before Supabase is ever called.
2. **Session gate** — the confirm route (`app/auth/confirm/route.ts`) checks the verified
   user's email after every successful link and signs out anyone who isn't the owner;
   `/owner` and the session-refresh proxy check the same predicate (`lib/owner.ts`).

The session gate is what makes custom SMTP safe to add: switching SMTP on (which removes the
built-in mailer's org-members-only delivery filter) does **not** open the app — widening access
is a deliberate code change to the gate, never a side effect of a mail setting. First owner
sign-in creates the owner's auth user (`shouldCreateUser` default). Custom-SMTP setup includes
one **mandatory** companion step: disable project-level signups (Auth → "Allow new users to
sign up"). This is not optional hardening — the `files`-bucket storage policies (below) admit
**any** authenticated user, and once SMTP delivers beyond the org, the public OTP endpoint
would let a stranger sign themselves up into exactly that class. Disable signups only
**after** the owner's first sign-in, which is what creates the owner's user. (On the built-in
mailer the same toggle is merely worthwhile anti-abuse: strangers' links never arrive, so all
they can create is dormant auth users.)

Why owner-only, and not a nicety: Supabase's **built-in mailer only delivers auth emails to the
project organisation's own members** (anything else fails with "Email address not authorized"),
at **2 emails per hour**, with a 60-second per-address cooldown and 1-hour link expiry. A
customer's magic link would silently never arrive. Consequences:

- `ownerEmail` **must be the org-member email** (the address the attendee signs into Supabase
  with). A different owner address ⇒ set up custom SMTP first.
- **"Customers can log in" is not what v1 ships.** What v1 does ship is custom SMTP
  (Resend/Postmark/etc.) configured in Supabase Auth settings, with signups disabled as its
  mandatory companion above — that makes the *owner's* own sign-in reliable from any address,
  and the app still signs in exactly one person. Letting customers create their own accounts is
  later, separate work: widening access at its one enforcement point (the `isOwnerEmail`
  predicate in the template's `lib/owner.ts`), re-enabling project-level signups, and the
  per-user storage policies below all land together or not at all. Widening the predicate on
  its own admits no *new* customer — with signups disabled Supabase will not create an account
  for one. It is not a clean no-op either, which is a further reason the three pieces land
  together: signups are disabled only **after** the owner's first sign-in, so any stranger who
  hit the public OTP endpoint before that already has a dormant auth user, and that account
  survives the toggle. Widen the predicate later with custom SMTP delivering and those dormant
  users' links start arriving — admitting them straight into the `files` bucket whose policies
  admit any authenticated user. If that work is ever built, note that the predicate is shared
  by the send action, the confirm route's session gate, `/owner` and the proxy; widening only
  the login action would leave customers receiving links that silently bounce at the session gate.
  `app-iterate` configures custom SMTP and stops there, and tells the owner plainly that
  customer accounts are a separate build rather than reporting them live.
- The 2/hour cap also bites the owner during testing: one failed send usually means "wait",
  and the template's login page says so.

**Both magic-link shapes are handled** by the template's `/auth/confirm` route, and both must
stay: free-tier projects created after 2026-06-03 cannot customize auth email templates on the
default mailer, so their links arrive in the default shape (Supabase verify endpoint →
`?code=...`, PKCE — works only in the browser that requested it, and the login page says so).
Custom-SMTP projects can use the customized `?token_hash=...&type=email` shape.

Dashboard wiring per app (app-builder does this once): Auth → URL Configuration → Site URL =
the live Vercel URL, plus `http://localhost:3000` in Redirect URLs for local dev.

### Owner smoke test (acceptance)

1. Open `<live-url>/login` (or the home page's "Owner sign-in" link).
2. Send the link to `ownerEmail` — which is the org-member email.
3. Click the emailed link → lands on `/owner` signed in; sign-out returns to `/login`.

The home-page health board includes an "Auth: owner email" check — red until `ownerEmail` is
set, so a missing owner never fails silently at sign-in time.

## Storage — one private bucket, owner-only

The template's storage pattern is a single private bucket `files`, created by a committed
migration (never by hand in the dashboard), with policies that allow only signed-in users —
which, under owner-only auth, means the owner. Uploads go through the app's Supabase client;
downloads use signed URLs (private bucket ⇒ no public links). Owner-only is not a stage on the
way to something else in v1: customer accounts are unbuilt work (auth, above), and if they are
ever built, per-user paths would need their own policies — a new migration, reviewed like any
other schema change, landing with the widened predicate and re-enabled signups, never before
them.

Storage-migration rules (the migration role does not own the storage schema):

- Bucket = `insert into storage.buckets (id, name, public) values (...) on conflict do nothing`.
- Policies = `create policy ... on storage.objects`, wrapped in a
  `do $$ ... exception when insufficient_privilege` block so a platform permission change can
  never abort a deploy (closed upstream question — see `known-issues/storage-policy-migrations.md`).
- **Never `alter table storage.objects ...`** (including `enable row level security`) — it fails
  with "must be owner"; RLS is already on.
