# Worked example — the notes box, three weeks later

The change conversation. Three weeks after
[Harbour Plumbing's job tracker](../trades-job-tracker/TRANSCRIPT.md) went live, Dave wants
one more thing on each job. This is the conversation that kills the "80% there, then stuck"
wall: a change is one plain-English ask, it rides the same rails as the build, and nothing
goes live without a yes. It also shows the single most common thing to find three quiet
weeks in — the free-plan database asleep — and what that looks like when it's handled
honestly.

**Who's who.** Same Dave, same laptop, same live app.

---

**Dave:** Can you add a notes box to each job? Little things like "waiting on parts" or
"gate code 4382".

**Claude:** That's your job tracker — **harbour-plumbing**, live at
https://harbour-plumbing.vercel.app. Before I touch anything, I check the ground under it.

*[Claude works: pulls the latest code — the repository is the truth, the laptop copy is just
a cache of it — and confirms the live site isn't sitting on a rolled-back version. Then
probes the database and gets errors back.]*

**Claude:** One thing before the notes box: your database has **gone to sleep** — three
quiet weeks, and that's the free-plan pause from your card. It's also why the app would've
shown errors if you'd opened it this morning. Wake it: Supabase dashboard → your project →
**Restore**. Tell me when it says the project is up.

**Dave:** Clicked it — restoring… right, it's up. So that's why it was carrying on this
morning.

**Claude:** That's the one. Now the change, said back before anything starts: a **notes**
box on each job — that's a new column in **jobs**. It's purely additive: nothing existing is
touched, nothing is lost, so there's no backup step needed today. When I push this it goes
straight onto your live site at https://harbour-plumbing.vercel.app — the same address your
customers use — and replaces what's there now. OK to go?

**Dave:** Yes, go ahead.

*[Claude works: adds the notes box to the job form and the job list, writes the new column
as a migration file committed alongside the code — never typed into a dashboard — and checks
the app still compiles cleanly, including the pack's rule that the app's little always-on
status page stays untouched. Then one push: code and database change travel together.]*

**Claude:** Pushed. Proving it — same discipline as build day:

**Check 1 of 4 — deployed by the push.** The live site is running the exact version just
pushed.

**Check 2 of 4 — the site answers 200.** https://harbour-plumbing.vercel.app, the real
address, not a preview.

**Check 3 of 4 — the database change applied.** The **notes** column is live — the database
change rode the same push as the code, about a minute behind it.

**Check 4 of 4 — the change is live on the page.** I opened a job on the live site — the
notes box is there.

Done. One thing to keep in your back pocket: if this change turns out wrong, one click rolls
the code back to the version before this one — Vercel dashboard → Deployments → **Instant
Rollback** — and tell me straight after you press it, because new changes stop going live
until I put the deploys back on track.

**Dave:** Can my customers log in too? Might be handy if they could check their own job.

**Claude:** Right now sign-in emails can only reach **you** — the free built-in mailer won't
deliver to anyone else, so a customer's sign-in link would simply never arrive. I can give
the app its own email sender today (a service like Resend or Postmark, wired into Supabase),
which makes your own sign-in reliable and is the first thing customer accounts would ever
need. Customer accounts themselves are a separate build — I'm not going to half-open the app
and leave your files reachable. It stays yours-only until that's done properly. Want the
email sender set up today?

**Dave:** Not today — the notes box was the job.

**Claude:** Then that's the visit: notes box live at the same address, nothing else touched.

---

**What Dave got:** the change he asked for, live in minutes, with the database asleep found
and fixed on the way in — and a straight answer about customer logins instead of a half-open
door. **What he never saw:** a branch, a migration command, a deploy button.
