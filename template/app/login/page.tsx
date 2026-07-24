import { redirect } from "next/navigation";
import { appConfig } from "@/app.config";
import { SetupPending } from "@/app/setup-pending";
import { isOwnerEmail } from "@/lib/owner";
import { createClient, hasSupabaseEnv } from "@/lib/supabase/server";
import { sendMagicLink } from "./actions";

export const dynamic = "force-dynamic";

const messages: Record<string, { kind: "ok" | "err"; text: string }> = {
  sent: {
    kind: "ok",
    text: "Sign-in link sent — open your email on THIS device. The link works once, expires in an hour, and only signs you in on the device that requested it.",
  },
  "no-owner": {
    kind: "err",
    text: "No owner email is set yet. Add it to app.config.ts (ownerEmail) and push.",
  },
  "not-owner": {
    kind: "err",
    text: "This app is owner-only right now. Customer sign-in is a separate step that needs custom email (SMTP) set up first — ask Claude about it.",
  },
  "send-failed": {
    kind: "err",
    text: "The link could not be sent. Supabase's built-in mailer allows only 2 emails per hour (and one request per minute) — wait and try again.",
  },
  "link-expired": {
    kind: "err",
    text: "That sign-in link didn't work. Links expire after an hour, work once, and must be opened on the same device that requested them. Request a fresh one below.",
  },
};

export default async function LoginPage({
  searchParams,
}: {
  searchParams: Promise<{ status?: string }>;
}) {
  if (!hasSupabaseEnv()) {
    return <SetupPending />;
  }

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  // Only the owner skips the form — a stray non-owner session must NOT
  // bounce to /owner (whose guard sends it back here: a loop).
  if (isOwnerEmail(user?.email)) {
    redirect("/owner");
  }

  const { status } = await searchParams;
  const message = status ? messages[status] : undefined;

  return (
    <main>
      <h1>{appConfig.businessName}</h1>
      <p className="tagline">Owner sign-in — no password, just a link.</p>
      <section className="card">
        <h2>Sign in</h2>
        <form action={sendMagicLink}>
          <input
            type="email"
            name="email"
            required
            placeholder="you@yourbusiness.com"
            autoComplete="email"
          />
          <button type="submit">Email me a sign-in link</button>
        </form>
        {message ? (
          <p className={message.kind === "ok" ? "notice ok" : "notice fail"}>
            {message.text}
          </p>
        ) : null}
      </section>
    </main>
  );
}
