# Create/delete round-trip proving account + org + authed CLI reach the Supabase API.
# Leaves nothing behind: sweeps leftovers first, refuses at the free-tier cap, deletes what it
# creates. Runs on pwsh and Windows PowerShell 5.1.
param(
    [string]$OrgId,
    [string]$Region = "ap-southeast-2",
    [int]$PollSeconds = 5
)

$ErrorActionPreference = "Continue"

function Fail([string]$Msg) {
    Write-Host "SMOKE FAIL: $Msg"
    exit 1
}

# -o json prints a bare JSON array on both CLI implementations; --output-format json wraps the
# payload in an envelope and must never be used here.
function Get-Projects {
    $json = supabase projects list -o json 2>$null
    if ($LASTEXITCODE -ne 0) { Fail "cannot list projects - transient API failure or lost auth (supabase login); re-run this script, it sweeps any leftover smoke project" }
    $text = ($json -join "`n").Trim()
    if (-not $text) { return @() }
    $parsed = $null
    try { $parsed = $text | ConvertFrom-Json -ErrorAction Stop }
    catch { Fail "cannot list projects - unparseable CLI output; re-run this script, it sweeps any leftover smoke project" }
    if ($null -eq $parsed) { return @() }
    $list = @($parsed)
    if ($list.Count -gt 0 -and -not $list[0].PSObject.Properties['name']) {
        Fail "cannot list projects - unexpected CLI output shape; re-run this script, it sweeps any leftover smoke project"
    }
    return $list
}

function Get-ProjectOrg([object]$Project) {
    if ($Project.PSObject.Properties['organization_id']) { return $Project.organization_id }
    return $Project.org_id
}

function Get-ProjectRef([object]$Project) {
    if ($Project.PSObject.Properties['id']) { return $Project.id }
    return $Project.ref
}

if (-not (Get-Command supabase -ErrorAction SilentlyContinue)) {
    Fail "supabase CLI not on PATH (CLI-SUPABASE)"
}

$orgsJson = supabase orgs list -o json 2>$null
if ($LASTEXITCODE -ne 0) { Fail "not logged in (SB-AUTH: supabase login)" }
$orgsText = ($orgsJson -join "`n").Trim()
$orgsParsed = $null
if ($orgsText) {
    try { $orgsParsed = $orgsText | ConvertFrom-Json -ErrorAction Stop }
    catch { Fail "cannot read orgs list - unparseable CLI output; re-run this script" }
}
$orgs = if ($null -eq $orgsParsed) { @() } else { @($orgsParsed) }
if ($orgs.Count -gt 0 -and -not $orgs[0].PSObject.Properties['id']) {
    Fail "cannot read orgs list - unexpected CLI output shape; re-run this script"
}
if ($orgs.Count -eq 0) { Fail "no organization (SB-ORG: supabase orgs create)" }
if (-not $OrgId) {
    if ($orgs.Count -gt 1) {
        Fail ("several organizations found - re-run with -OrgId, one of: " + (($orgs | ForEach-Object { $_.id }) -join ", "))
    }
    $OrgId = $orgs[0].id
}

$goneStatuses = @('REMOVED', 'GOING_DOWN')

# A stranded smoke project from an interrupted run eats a free-tier slot - sweep before counting.
$leftovers = @(Get-Projects | Where-Object { (Get-ProjectOrg $_) -eq $OrgId -and $_.name -like 'fsbp-smoke-*' -and $_.status -notin $goneStatuses })
foreach ($p in $leftovers) {
    $leftoverRef = Get-ProjectRef $p
    Write-Host "Sweeping leftover smoke project $($p.name) ($leftoverRef)"
    supabase projects delete $leftoverRef --yes | Out-Null
    if ($LASTEXITCODE -ne 0) { Fail "could not delete leftover $($p.name) - have the owner remove it at https://supabase.com/dashboard/project/$leftoverRef/settings/general, then re-run" }
}

# Free-tier cap (~2 active projects per org, CONVENTIONS.md convention 6). Creating past it is
# the Supabase Pro decision ($25/mo plus usage-based compute) - the owner's call, never a smoke
# test's side effect.
$active = @(Get-Projects | Where-Object { (Get-ProjectOrg $_) -eq $OrgId -and $_.status -notin (@('INACTIVE') + $goneStatuses) })
if ($active.Count -ge 2) {
    Fail "org $OrgId already has $($active.Count) active projects - the free-tier cap (~2), where creating one more means Supabase Pro (`$25/mo plus usage-based compute), the owner's decision. This guard refuses at the cap regardless of plan; it is built for workshop-fresh free orgs. Never delete an existing project to make room - the only moves are the owner choosing Supabase Pro or a different org."
}

$name = "fsbp-smoke-{0:x6}" -f (Get-Random -Maximum 16777215)
$chars = [char[]]"ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789"
$dbPassword = -join (1..24 | ForEach-Object { $chars | Get-Random })
Write-Host "Creating throwaway project $name in org $OrgId ($Region)"
supabase projects create $name --org-id $OrgId --db-password $dbPassword --region $Region | Out-Host
if ($LASTEXITCODE -ne 0) { Fail "project create failed" }

# Verify from the world: the project must appear in the list before it counts as created.
$ref = $null
foreach ($attempt in 1..12) {
    $hit = @(Get-Projects | Where-Object { $_.name -eq $name }) | Select-Object -First 1
    if ($hit) { $ref = Get-ProjectRef $hit; break }
    Start-Sleep -Seconds $PollSeconds
}
if (-not $ref) { Fail "created project $name never appeared in projects list - delete it in the dashboard before re-running" }

Write-Host "Deleting $name ($ref)"
supabase projects delete $ref --yes | Out-Host
if ($LASTEXITCODE -ne 0) { Fail "delete failed - have the owner remove it at https://supabase.com/dashboard/project/$ref/settings/general (a leftover project eats a free-tier slot)" }

$still = @()
foreach ($attempt in 1..12) {
    $still = @(Get-Projects | Where-Object { (Get-ProjectRef $_) -eq $ref -and $_.status -notin $goneStatuses })
    if ($still.Count -eq 0) { break }
    Start-Sleep -Seconds $PollSeconds
}
if ($still.Count -gt 0) { Fail "project $ref still listed after delete - re-run to sweep it, or remove it in the dashboard" }

Write-Host "SMOKE PASS: created and deleted $name ($ref) in org $OrgId ($Region)"
exit 0
