import { createServerClient } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";
import { isOwnerEmail } from "@/lib/owner";

/**
 * Refreshes the auth session on every request the matcher admits, and guards
 * /owner. Runs from proxy.ts at the repo root — see there for which paths the
 * matcher deliberately leaves out (`/up` among them).
 */
export async function updateSession(request: NextRequest) {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const anonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

  // Before env vars are wired the health page must still render — skip auth.
  if (!url || !anonKey) {
    return NextResponse.next({ request });
  }

  let supabaseResponse = NextResponse.next({ request });

  const supabase = createServerClient(url, anonKey, {
    cookies: {
      getAll() {
        return request.cookies.getAll();
      },
      setAll(cookiesToSet) {
        cookiesToSet.forEach(({ name, value }) =>
          request.cookies.set(name, value),
        );
        supabaseResponse = NextResponse.next({ request });
        cookiesToSet.forEach(({ name, value, options }) =>
          supabaseResponse.cookies.set(name, value, options),
        );
      },
    },
  });

  // Do not run code between createServerClient and getUser() — a stale
  // session can be written back to the browser otherwise.
  const {
    data: { user },
  } = await supabase.auth.getUser();

  // /owner is for the owner alone — not merely "signed in". A non-owner
  // session can't normally exist (the confirm route signs them out at
  // issuance), but the gate here doesn't depend on that.
  if (
    request.nextUrl.pathname.startsWith("/owner") &&
    !isOwnerEmail(user?.email)
  ) {
    const redirectUrl = request.nextUrl.clone();
    redirectUrl.pathname = "/login";
    redirectUrl.search = "";
    return NextResponse.redirect(redirectUrl);
  }

  return supabaseResponse;
}
