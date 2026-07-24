import { type EmailOtpType } from "@supabase/supabase-js";
import { redirect } from "next/navigation";
import { type NextRequest } from "next/server";
import { isOwnerEmail } from "@/lib/owner";
import { createClient, hasSupabaseEnv } from "@/lib/supabase/server";

/**
 * Magic-link landing: verifies the emailed token and starts the session.
 *
 * Handles both link shapes Supabase sends:
 * - `?code=...` — the default email template (free-tier projects created
 *   after 2026-06-03 cannot customize templates without custom SMTP; the
 *   default link goes via Supabase's verify endpoint and lands here with a
 *   PKCE code). Must be opened in the same browser that requested it.
 * - `?token_hash=...&type=email` — the customized-template shape used once
 *   custom SMTP is set up.
 */
export async function GET(request: NextRequest) {
  if (!hasSupabaseEnv()) {
    redirect("/login");
  }

  const { searchParams } = new URL(request.url);
  const token_hash = searchParams.get("token_hash");
  const type = searchParams.get("type") as EmailOtpType | null;
  const code = searchParams.get("code");
  const nextParam = searchParams.get("next") ?? "/owner";
  // Stay on this app: allow only a plain in-app path of printable ASCII.
  // "//host" and "/\host" are protocol-relative escapes; control chars can
  // smuggle those past URL parsers (they strip \t \r \n); and anything past
  // ASCII throws when the Location header is written — a 500 after the
  // one-time link has already been consumed.
  const next = /^\/(?![/\\])[\x20-\x7e]*$/.test(nextParam)
    ? nextParam
    : "/owner";

  const supabase = await createClient();

  let verified = false;
  if (token_hash && type) {
    const { error } = await supabase.auth.verifyOtp({ type, token_hash });
    verified = !error;
  } else if (code) {
    const { error } = await supabase.auth.exchangeCodeForSession(code);
    verified = !error;
  }

  if (!verified) {
    redirect("/login?status=link-expired");
  }

  // Session gate, not just a send gate: whoever the link was for, only the
  // owner keeps a session. The login form already refuses other addresses,
  // but Supabase's OTP endpoint is publicly callable with the anon key —
  // and once custom SMTP is added, the built-in mailer's org-members-only
  // filter no longer protects delivery. This check keeps the APP owner-only,
  // but only for sessions minted through this route — the storage policies
  // admit any signed-in user, so setting up custom SMTP must start with
  // disabling public signups (see supabase/README.md).
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!isOwnerEmail(user?.email)) {
    await supabase.auth.signOut();
    redirect("/login?status=not-owner");
  }

  redirect(next);
}
