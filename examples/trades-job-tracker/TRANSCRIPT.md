# Worked example — Harbour Plumbing's job tracker

A two-person plumbing outfit gets a job tracker it will actually run the business on — which
is exactly why this conversation has one beat the salon example doesn't: **the money gate**.
An app the business uses is business use, and the pack names the real running costs before
anything exists, not after. The build itself rides the same rails as
[Rosa's booking page](../salon-booking/TRANSCRIPT.md), so the middle is told more briefly
here.

**Who's who.** **Dave** runs Harbour Plumbing — him and an apprentice. Foundation setup
already passed on his laptop (the green PASS banner, everyday browser connected). Lines like
*[Claude works: …]* are Claude doing things, narrated.

---

**Dave:** I run a plumbing business, Harbour Plumbing. I want a job tracker: every job with
the customer's name, the address, what stage it's at — quoted, booked, in progress, done,
invoiced — and the quote amount. Me and my apprentice will use it day to day for real jobs,
starting this week. Email's dave@harbour-plumbing.example.

**Claude:** Here's the plan, in your words — and because you said *real jobs, day to day*,
the money comes first, before anything exists:

- **How it'll be used: for the business.** That changes the plans you're on. The free tiers
  are an evaluation window measured in days — not a place to run a business. Business use
  means both platforms go paid: **Vercel Pro ($20/mo)** and **Supabase Pro ($25/mo plus
  usage-based compute — the bill scales with real use, never a flat $25)**. Two honest ways
  to go: **(a) evaluate free first** — this week is you and the apprentice kicking the tyres,
  personal audience only, and you upgrade before any customer traffic or links from your
  site; or **(b) upgrade now** and it's business-ready from day one. Which way?

**Dave:** Evaluate free first — give me the week. Nothing customer-facing till we've
upgraded, understood.

**Claude:** Recorded, and it'll be on your card at the end so it doesn't get lost. The rest
of the plan:

- **What it does:** a job tracker — every job with customer, address, stage (quoted, booked,
  in progress, done, invoiced) and quote amount. You add and update jobs from your phone;
  the list lives behind your owner sign-in.
- **The name on the page:** Harbour Plumbing.
- **Your sign-in email:** dave@harbour-plumbing.example.
- **First table:** jobs. Anything more can be added later by asking.

Happy for me to build this?

**Dave:** Yes, build it.

*[Claude works: the same rails as every build — a private repository called
**harbour-plumbing** under Dave's own account, connected to Vercel with "every save goes
live automatically" switched on, before any feature exists.]*

**Claude:** The Vercel project's **Domains** settings are open in your usual browser profile —
read me the address there.

**Dave:** It says harbour-plumbing.vercel.app.

*[Claude works: checks the database account against the free plan's limit — room — then
creates the **harbour-plumbing** database project in Sydney.]*

**Claude:** Database password's generated — into your **password manager**, and I keep it
nowhere.

**Dave:** In the password manager.

**Claude:** Your two dashboard clicks, same as every build — each page opened in that same
browser profile. First: **Project Settings →
Integrations → GitHub** — connect **harbour-plumbing**, working directory ".", **Deploy to
production** on for the main branch, then reload and look for the connected repository and a
**Disable integration** button.

**Dave:** Done — harbour-plumbing's connected and the Disable integration button's there.

**Claude:** Second: **Auth → URL Configuration** — Site URL to
https://harbour-plumbing.vercel.app, and http://localhost:3000 added to the Redirect URLs.

**Dave:** Done — Site URL's the live one, localhost's in the list.

*[Claude works: database keys into Vercel (never into the code), template copied in,
business name and owner email filled, the job list and add-a-job form built, the **jobs**
table written as a migration file that travels with the code — stage is a dropdown of the
five stages Dave named. Compiles cleanly. One push: code and database change go live
together.]*

**Claude:** Push made. Proving it:

**Proof 1 of 4 — deployed by the push.** The live site is running the exact version just
pushed — no hand-publishing, ever.

**Proof 2 of 4 — the app is live.** https://harbour-plumbing.vercel.app answers 200.

**Proof 3 of 4 — the database is ready.** The **jobs** table is live behind the app.

Last one's yours. Open https://harbour-plumbing.vercel.app/login, send the link to
dave@harbour-plumbing.example, and open your email in the same browser — the first email is
titled **"Confirm your email address"**, which is normal. Where do you land?

**Dave:** I'm in — owner page, empty jobs list.

**Claude:** **Proof 4 of 4 — owner sign-in works.** All four. Your card:

> # Harbour Plumbing — you're live
>
> **Your app:** https://harbour-plumbing.vercel.app
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
> **The money, straight:** You said this app is for the business. Before customers touch it,
> move both plans to paid: **Vercel Pro ($20/month)** and **Supabase Pro ($25/month plus
> usage-based compute — the bill scales with real use)**. That's the default recommendation,
> not fine print: the free tiers are an evaluation window measured in days, and business
> traffic on them breaks both the rules and, eventually, the app.
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

**Dave:** Good. And when the week's up and we want changes?

**Claude:** You ask for them in plain English and they go live at the same address — that
conversation is the next worked example:
[the notes box, three weeks later](../job-tracker-notes-box/TRANSCRIPT.md). And when the
tracker starts holding real customer jobs, that's the upgrade moment we recorded — say the
word and both Pros get switched on first.

---

**What Dave got:** a job tracker his business will actually run on, at a real address, on
his own accounts — with the true running cost said once, up front, instead of discovered in
a bill. **What he never saw:** a framework choice, a deploy command, a config file.
