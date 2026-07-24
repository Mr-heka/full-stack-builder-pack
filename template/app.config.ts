/**
 * App identity. app-builder fills these from the attendee's answers
 * during scaffolding — businessName is the page heading and browser-tab
 * title; ownerEmail is the one address that can sign in.
 */
export const appConfig = {
  businessName: "Your Business",

  /**
   * Owner-only auth: this is the ONLY email the app will send a sign-in
   * link to (see supabase/README.md). It must be the same address that
   * owns the Supabase organisation — Supabase's built-in mailer only
   * delivers auth emails to the project org's own members. A different
   * owner address needs custom SMTP set up first.
   */
  ownerEmail: "",
};
