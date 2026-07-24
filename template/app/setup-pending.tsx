import { appConfig } from "@/app.config";

/**
 * Rendered in place of the auth pages until the Supabase env vars are
 * wired — a plain setup note instead of a crash.
 */
export function SetupPending() {
  return (
    <main>
      <h1>{appConfig.businessName}</h1>
      <p className="tagline">This app is live — finishing setup.</p>
      <section className="card">
        <h2>Still finishing setup</h2>
        <p className="hint">
          Sign-in isn&apos;t switched on yet — the app is missing its Supabase
          connection details, the <code>NEXT_PUBLIC_SUPABASE_URL</code> and{" "}
          <code>NEXT_PUBLIC_SUPABASE_ANON_KEY</code> env vars. Add them where
          the app is hosted and redeploy; the home page&apos;s health check
          shows when everything is connected.
        </p>
      </section>
      <p className="footer-link">
        <a href="/">← Back to the health check</a>
      </p>
    </main>
  );
}
