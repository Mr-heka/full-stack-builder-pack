import { type NextRequest } from "next/server";
import { updateSession } from "@/lib/supabase/proxy";

export async function proxy(request: NextRequest) {
  return await updateSession(request);
}

export const config = {
  // Everything except static assets and /up — auth cookies must refresh on
  // every page the owner or a customer actually uses. /up is the liveness
  // route the day-30 sweep pings (app/up/page.tsx): excluded so that ping
  // reaches static HTML and never runs a Supabase client at all. `up/?$`
  // covers both /up and /up/ — never rely on the trailing-slash redirect to
  // keep the proxy off that path. The `$` keeps /upload and /uploads matched.
  matcher: [
    "/((?!_next/static|_next/image|favicon.ico|up/?$|.*\\.(?:svg|png|jpg|jpeg|gif|webp|ico)$).*)",
  ],
};
