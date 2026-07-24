#!/usr/bin/env bash
# Create/delete round-trip proving account + org + authed CLI reach the Supabase API.
# Leaves nothing behind: sweeps leftovers first, refuses at the free-tier cap, deletes what it
# creates.
set -u

ORG_ID=""
REGION="ap-southeast-2"
POLL_SECONDS=5
while [ $# -gt 0 ]; do
  case "$1" in
    --org-id|--region|--poll-seconds)
      [ $# -ge 2 ] || { echo "SMOKE FAIL: $1 needs a value"; exit 1; }
      case "$1" in
        --org-id) ORG_ID="$2" ;;
        --region) REGION="$2" ;;
        --poll-seconds) POLL_SECONDS="$2" ;;
      esac
      shift 2 ;;
    *) echo "SMOKE FAIL: unknown argument $1"; exit 1 ;;
  esac
done

fail() { echo "SMOKE FAIL: $1"; exit 1; }

command -v supabase >/dev/null 2>&1 || fail "supabase CLI not on PATH (CLI-SUPABASE)"
command -v jq >/dev/null 2>&1 || fail "jq is required (brew install jq)"

# -o json prints a bare JSON array on both CLI implementations; --output-format json wraps the
# payload in an envelope and must never be used here.
orgs_json=$(supabase orgs list -o json 2>/dev/null) \
  || fail "not logged in (SB-AUTH: supabase login)"
printf '%s' "$orgs_json" | jq -e 'type=="array"' >/dev/null 2>&1 \
  || fail "cannot read orgs list - output was not a JSON array; re-run this script"
org_count=$(printf '%s' "$orgs_json" | jq '(. // []) | length')
[ "$org_count" -gt 0 ] || fail "no organization (SB-ORG: supabase orgs create)"
if [ -z "$ORG_ID" ]; then
  if [ "$org_count" -gt 1 ]; then
    fail "several organizations found - re-run with --org-id, one of: $(printf '%s' "$orgs_json" | jq -r '[.[].id] | join(", ")')"
  fi
  ORG_ID=$(printf '%s' "$orgs_json" | jq -r '.[0].id')
fi

list_projects() {
  local out
  out=$(supabase projects list -o json 2>/dev/null) || return 1
  printf '%s' "$out" | jq -e 'type=="array"' >/dev/null 2>&1 || return 1
  printf '%s' "$out"
}
LIST_FAIL="cannot list projects - CLI failure, non-array output, or lost auth (supabase login); re-run this script, it sweeps any leftover smoke project"

# A stranded smoke project from an interrupted run eats a free-tier slot - sweep before counting.
proj_json=$(list_projects) || fail "$LIST_FAIL"
for leftover_ref in $(printf '%s' "$proj_json" | jq -r --arg org "$ORG_ID" \
    '(. // []) | .[] | select((.organization_id // .org_id) == $org and (.name | startswith("fsbp-smoke-")) and .status != "REMOVED" and .status != "GOING_DOWN") | (.id // .ref)'); do
  echo "Sweeping leftover smoke project $leftover_ref"
  supabase projects delete "$leftover_ref" --yes >/dev/null 2>&1 \
    || fail "could not delete leftover $leftover_ref - have the owner remove it at https://supabase.com/dashboard/project/$leftover_ref/settings/general, then re-run"
done

# Free-tier cap (~2 active projects per org, CONVENTIONS.md convention 6). Creating past it is
# the Supabase Pro decision ($25/mo plus usage-based compute) - the owner's call, never a smoke
# test's side effect.
proj_json=$(list_projects) || fail "$LIST_FAIL"
active=$(printf '%s' "$proj_json" | jq --arg org "$ORG_ID" \
  '[(. // []) | .[] | select((.organization_id // .org_id) == $org and .status != "INACTIVE" and .status != "REMOVED" and .status != "GOING_DOWN")] | length')
if [ "$active" -ge 2 ]; then
  fail "org $ORG_ID already has $active active projects - the free-tier cap (~2), where creating one more means Supabase Pro (\$25/mo plus usage-based compute), the owner's decision. This guard refuses at the cap regardless of plan; it is built for workshop-fresh free orgs. Never delete an existing project to make room - the only moves are the owner choosing Supabase Pro or a different org."
fi

name="fsbp-smoke-$(od -An -N3 -tx1 /dev/urandom | tr -d ' \n')"
db_password=$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 24)
echo "Creating throwaway project $name in org $ORG_ID ($REGION)"
supabase projects create "$name" --org-id "$ORG_ID" --db-password "$db_password" --region "$REGION" \
  || fail "project create failed"

# Verify from the world: the project must appear in the list before it counts as created.
ref=""
attempt=0
while [ "$attempt" -lt 12 ]; do
  proj_json=$(list_projects) || fail "$LIST_FAIL"
  ref=$(printf '%s' "$proj_json" | jq -r --arg n "$name" \
    '(. // []) | .[] | select(.name == $n) | (.id // .ref)' | head -n1)
  [ -n "$ref" ] && break
  attempt=$((attempt + 1))
  sleep "$POLL_SECONDS"
done
[ -n "$ref" ] || fail "created project $name never appeared in projects list - delete it in the dashboard before re-running"

echo "Deleting $name ($ref)"
supabase projects delete "$ref" --yes \
  || fail "delete failed - have the owner remove it at https://supabase.com/dashboard/project/$ref/settings/general (a leftover project eats a free-tier slot)"

still=1
attempt=0
while [ "$attempt" -lt 12 ]; do
  proj_json=$(list_projects) || fail "$LIST_FAIL"
  still=$(printf '%s' "$proj_json" | jq --arg r "$ref" \
    '[(. // []) | .[] | select((.id // .ref) == $r and .status != "REMOVED" and .status != "GOING_DOWN")] | length')
  [ "$still" -eq 0 ] && break
  attempt=$((attempt + 1))
  sleep "$POLL_SECONDS"
done
[ "$still" -eq 0 ] || fail "project $ref still listed after delete - re-run to sweep it, or remove it in the dashboard"

echo "SMOKE PASS: created and deleted $name ($ref) in org $ORG_ID ($REGION)"
exit 0
