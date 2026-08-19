# Worked example — Rosa's booking page

A hair-and-beauty salon gets a booking page with an owner-only list behind it. This is the
whole conversation, start to finish — about forty minutes, most of it Claude working while
Rosa watches. Nothing here is polished after the fact: this is the shape every build takes.

**Who's who.** **Rosa** owns Rosa's Hair & Beauty. She has never built software. Before this
conversation her laptop already passed the pack's foundation setup — the full-screen green
PASS banner, accounts and sign-ins done, her everyday browser connected — so links Claude
opens land in the Chrome profile she actually uses. Lines like *[Claude works: …]* are Claude doing
things, narrated so you can see the shape of the work without reading a single command.

---

**Rosa:** I run a hair and beauty salon — Rosa's Hair & Beauty. I want a page where clients
can book in: name, phone number, what they want done, and when they'd like to come in. And a
list only I can see, so I can check the day's bookings from my phone. Could clients pay a
deposit when they book? My email is rosa@rosas-hair-beauty.example. It's just to show my sister and a
couple of regulars for now — nothing official yet.

**Claude:** Here's the plan, in your words — one screen, and nothing gets built until you say
yes to it:

- **What it does:** a booking page — clients enter their name, phone, the service, and when
  they'd like to come in. Every booking lands in a **bookings** list only you can see, behind
  your owner sign-in. Works on a phone.
- **Deposits:** the app won't handle payments itself — card handling brings compliance and
  liability a workshop app shouldn't carry. The working shortcut: create a **payment link in
  your Stripe dashboard** and we paste it into the app as a button. Same money arrives, none
  of the risk lives in your code.
- **The name on the page:** Rosa's Hair & Beauty.
- **Your sign-in email:** rosa@rosas-hair-beauty.example — sign-in links go there, and only there,
  for now.
- **How it'll be used:** evaluation — showing your people, not linked anywhere public. The
  day it becomes something the business runs on, both platforms move to their paid plans
  first; the numbers are on your card at the end.
- **First table:** bookings. Anything more can be added later by asking.

Happy for me to build this?

**Rosa:** Yes, build it. And the Stripe trick for deposits is fine — I'll do that later.

*[Claude works: creates the app's home on GitHub — a private repository called
**rosas-hair-beauty**, under Rosa's own account — then connects it to Vercel, the service
that publishes the app to the internet, and switches on "every save goes live automatically".
No feature exists yet. The pipeline comes first, on purpose: an app born this way can never
be stranded on one laptop.]*

**Claude:** One look-and-read for you — your dashboards are yours, I don't click in them.
I've opened the Vercel project's **Domains** settings in your usual browser profile — read me
the web address shown there.

**Rosa:** It says rosas-hair-beauty.vercel.app.

**Claude:** That's the app's live address from here on. Next, the database.

*[Claude works: checks Rosa's database account against the free plan's limit first — 0 of
roughly 2 free projects used, so there's room — then creates a database project called
**rosas-hair-beauty** in Sydney.]*

**Claude:** I've generated the database password. Save it in your **password manager** now —
day to day the app never uses it, and I keep it nowhere.

**Rosa:** Saved in my password manager.

**Claude:** Two settings only you can click, both in your Supabase dashboard. I'll open each
one in that same browser profile, you read back what you see.

First: **Project Settings → Integrations → GitHub**. Connect it to **rosas-hair-beauty**,
leave the working directory as ".", and turn on **Deploy to production** for the main branch.
Then reload the page — it should show the connected repository and a **Disable integration**
button. That button being there is how we know it took.

**Rosa:** Done — it shows rosas-hair-beauty connected, and there's a Disable integration
button.

**Claude:** That's what makes database changes travel the same one-way street as the code —
one save, both arrive together. Second: **Auth → URL Configuration**. Set the Site URL to
https://rosas-hair-beauty.vercel.app, and add http://localhost:3000 to the Redirect URLs.

**Rosa:** Done — Site URL is the live address, and localhost 3000 is in the redirect list.

*[Claude works: gives the app its database keys through Vercel — never saved into the code —
copies the pack's app template into place, fills in the business name and owner email, builds
the booking page and the owner-only list, and writes the **bookings** table as a migration
file that travels with the code. Checks the whole thing compiles cleanly. Then one push: code
and database change go live together.]*

**Claude:** Push made. Now I prove it — four proofs, in order, and I don't call this done
until all four pass:

**Proof 1 of 4 — deployed by the push.** The live site is running the exact version just
pushed. It went live *because* of the push — not because of anything done by hand — and
that's the habit that keeps every future change a one-liner.

**Proof 2 of 4 — the app is live.** https://rosas-hair-beauty.vercel.app answers 200 — the
web's way of saying "all good".

**Proof 3 of 4 — the database is ready.** The **bookings** table is live behind the app —
the exact change committed is the change that applied.

The last proof is yours to do — the sign-in. Open
https://rosas-hair-beauty.vercel.app/login, enter rosa@rosas-hair-beauty.example, and press send. Then
open your email **in the same browser**. One thing to know: this very first email is titled
**"Confirm your email address"** — that's normal, it's creating your sign-in; only later ones
say sign-in. Click the link and tell me where you land.

**Rosa:** Got the email, clicked it — I'm looking at the owner page. There's an empty
bookings list!

**Claude:** **Proof 4 of 4 — owner sign-in works.** That's all four. Here's your card — keep
it:

> # Rosa's Hair & Beauty — you're live
>
> **Your app:** https://rosas-hair-beauty.vercel.app
>
> *[a QR square is drawn right in the terminal]* Point your phone's camera at the square and
> it opens.
>
> **Share it — to your people, for now.** Show it off to family and friends: "I built this
> today, and it's live on the internet." Hold off on linking it from the business website,
> sending it to customers, or promoting it — that's business use, and it waits for the Pro
> step below.
>
> **Want it changed? Just ask.** Open Claude and say it in plain English — "add a notes box
> to each job" — and the app-iterate skill makes the change and pushes it live. You never
> touch code.
>
> **The money, straight:** While you're evaluating — showing your people, kicking the tyres —
> the free tiers are fine. The day this app starts working for the business (customers using
> it, linked from your site, promoted anywhere), move to **Vercel Pro ($20/month)** and
> **Supabase Pro ($25/month plus usage-based compute)** first. Pro by default for anything
> business-facing.
>
> **One warning that will bite:** on the free database plan, your app's database **goes to
> sleep after about a week of nobody using it** — the app then shows errors until you wake it
> (one click: Supabase dashboard → your project → Restore). If the app "breaks" in a couple
> of weeks, it is almost certainly this, and it's a one-click fix.
>
> **Your own web address:** want this at yourbusiness.com.au instead of .vercel.app? That's a
> ten-minute job we can do next — say the word.
>
> **Day-30 check-in:** in about a month we'd like to check your app is still up — one ping of
> its public page, plus a status read through Supabase's management API that tells us whether
> the database has gone to sleep (the page ping alone can't see that). Neither reads your
> data nor wakes the database. If you'd rather we didn't, say so now and we won't.
>
> **Keep the momentum:** the Loop is Selr's community of owners who built apps just like this
> one — people post what they shipped, what worked, and what they charged. The apps that
> survive past month one belong to owners who stayed in the room. Ask us for an invite.

**Rosa:** That's actually my page. What happens when I want to change something?

**Claude:** You say it, in plain English, and it changes — same address, no code. That's its
own short conversation: see [a change to a live app](../job-tracker-notes-box/TRANSCRIPT.md).

---

**What Rosa got:** a live booking page at a real address, on her own accounts, where every
future save goes live automatically — plus an owner-only list behind her email sign-in.
**What she never saw:** a framework choice, a deploy command, a config file.
