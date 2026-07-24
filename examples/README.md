# Worked examples — what building an app here actually looks like

Three real conversations, written down in full. No code knowledge needed to read them —
that's the point. If you're wondering "what would I actually say, and what happens next?",
these are the answer.

| Example | What it shows | Roughly |
|---|---|---|
| [Rosa's booking page](salon-booking/TRANSCRIPT.md) | A salon gets a booking page, from first ask to live address — including what happens when you ask for something the pack won't build (card payments) | 40 min |
| [Harbour Plumbing's job tracker](trades-job-tracker/TRANSCRIPT.md) | A trades business builds an app it will *actually run on* — so the real monthly costs get named before anything exists | 40 min |
| [The notes box, three weeks later](job-tracker-notes-box/TRANSCRIPT.md) | Changing a live app by asking — plus what it looks like when the free-plan database has gone to sleep, and a straight answer to "can my customers log in?" | 15 min |

## How to read them

- **Bold names** are the two speakers: the owner, and Claude.
- Lines like *[Claude works: …]* are Claude doing things — narrated so you can see the shape
  of the work without reading a single command.
- The indented card near the end of each build is real: every build ends with that card, your
  version filled in with your app's address.

## What you'll notice in all three

- **Nothing is built before you say yes to a one-screen plan** — and the plan ends with the
  same question every time: *"Happy for me to build this?"*
- **Your dashboards are yours.** When a setting needs clicking, you click it and read back
  what you see. Claude never signs in as you.
- **Done is proven, not declared.** Every build ends on four proofs, every change on four
  checks — said out loud, one by one, and the last word waits until they pass.
- **The app is live from day one**, at a real address, on your own accounts. There is no
  "we'll deploy it later".

## What the examples refuse — on purpose

You'll see the pack say no twice, in plain English, with a way forward each time: card
payments inside the app (the answer is a Stripe payment link pasted in as a button) and
customer logins (sign-in stays owner-only until the app gets its own email sender and the
customer side is built properly). If an ask is off the path, the answer is a redirect you
can understand — never a workaround you'd have to maintain.

---

These conversations are also the pack's nightly test scripts: every night, an automated run
builds these same apps for real — live address and all — then tears them down. When one of
the platforms moves a button, the nightly run catches it before a workshop does. The machine
half lives in [`qa/worked-examples/`](../qa/worked-examples/) — maintainers' territory,
nothing an owner ever needs to open.
