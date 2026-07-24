# App template

The starting point for every app built with the Selr AI full-stack builder pack:
Next.js (App Router) + Supabase + Vercel + GitHub. The home page is a health check
proving what every app needs before features exist — environment variables flow
from Vercel, the app can reach its Supabase project, and an owner email is set.
Sign-in is built in: an owner-only magic link (no passwords).

Read `CONVENTIONS.md` first — it is the one blessed path every app follows.

## Get your own copy (the golden path)

Ask Claude to build your app — the pack's `app-builder` skill copies this `template/` folder out
of the pack, injects `CONVENTIONS.md`, pushes it all to a new **private repo under your own
GitHub account**, then fills in your business name and owner email at the scaffold step.

Doing it by hand? Copy this folder somewhere short (e.g. `~/apps/<your-app>`), copy the pack's
`CONVENTIONS.md` in next to this README, put your business name and owner email in
`app.config.ts` (`businessName`, `ownerEmail`), then:

```sh
cd <your-app>
git init -b main && git add -A && git commit -m "app template"
gh repo create <your-account>/<your-app> --private --source . --push
```

## Deploy

1. Import the repo at [vercel.com/new](https://vercel.com/new) (sign in with GitHub).
2. In the Vercel project, add the two environment variables from `.env.example`
   (values: Supabase dashboard → Project → Settings → API).
3. Link the database to the repo so schema deploys on push too: see
   `supabase/README.md` (GitHub integration + auth URL settings — two minutes,
   once).
4. Put your email in `app.config.ts` (`ownerEmail`) — the one address that can
   sign in. It must be the email you use for Supabase itself; any other sign-in
   audience needs custom SMTP first.
5. Push to `main`. Push = deploy — code (Vercel) **and** schema (Supabase) update
   on every push.

The home page shows green ✓ across the board when envs, Supabase, and the owner
email are wired. Changed an env var in Vercel later? Redeploy (push anything, or
Vercel → Redeploy) for it to take effect.

## Local development

```sh
npm install
npx vercel env pull .env.local   # envs live in Vercel, never in the repo
npm run dev
```

## Sign in

The app has one sign-in method: a magic link emailed to the owner (`ownerEmail`
in `app.config.ts`) — no passwords. Follow "Owner sign-in" from the home page,
send yourself the link, and open it **on the same device**. Supabase's built-in
mailer allows 2 emails per hour, which is plenty for one owner; "customers can
log in" is a separate step that needs custom SMTP first — ask Claude about it.

## Layout

- `app.config.ts` — your business name (heading + tab title) and owner email (sign-in)
- `app/` — pages (Next.js App Router); `app/owner/` is the signed-in owner area
- `app/up/` — `/up`, a static liveness page. The day-30 check-in pings this and never the
  home page, so the check can't wake a sleeping database; never delete or move it, never wire it
  to anything read at request time, and keep it excluded from `proxy.ts`'s matcher
- `lib/supabase/` — database + auth clients (browser, server, session refresh)
- `supabase/migrations/` — committed schema migrations, applied on push to `main`
- `CONVENTIONS.md` — the blessed path this app follows (injected from the pack at creation)
