import { appConfig } from "@/app.config";

/**
 * True only when the given email is the configured owner. With no
 * ownerEmail set, nobody is the owner — the app fails closed.
 */
export function isOwnerEmail(email: string | null | undefined): boolean {
  const owner = appConfig.ownerEmail.trim().toLowerCase();
  return Boolean(owner) && (email ?? "").trim().toLowerCase() === owner;
}
