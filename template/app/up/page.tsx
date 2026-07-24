/**
 * Liveness route — deliberately static, and it must stay that way.
 *
 * The day-30 still-live sweep pings THIS route, never the home page: the home
 * page is `force-dynamic` and calls Supabase on every render, and a
 * DB-touching ping resets the free tier's idle timer and fakes its own
 * evidence (CONVENTIONS.md, convention 6, cliff 2). `force-static` is the
 * guarantee: no Supabase client, no cookies/headers/searchParams, nothing
 * read at request time. `proxy.ts` excludes `/up` from the auth proxy for the
 * same reason — the proxy refreshes the session on every other path.
 *
 * `next build` must keep printing `○ /up` (Static). If it ever prints `ƒ`,
 * this page is wired to something dynamic and the promise on the next-steps
 * card is no longer true.
 */
export const dynamic = "force-static";

export default function Up() {
  return (
    <main>
      <h1>Up</h1>
      <p className="tagline">This app is deployed and serving.</p>
      <p className="footer-link">
        <a href="/">← Health check</a>
      </p>
    </main>
  );
}
