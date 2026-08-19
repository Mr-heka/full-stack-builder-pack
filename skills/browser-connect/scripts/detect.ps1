# browser-connect detect (Windows) — daily browser + ranked Chromium profiles + pick, as JSON.
# Read-only: no writes, no prompts, no network. JSON on stdout, always.
#
# UNTESTED: written to the same spec as detect.sh but not yet run through a Windows QA pass.
# Treat its output as unverified until that pass lands. Known QA target: with exactly one
# profile, ConvertTo-Json (Windows PowerShell 5.1) may unroll the single-element profiles
# array to a bare object — consumers indexing profiles[0] should verify on a one-profile box.
#
# Daily browser = HKCU UrlAssociations\https\UserChoice ProgId.
# Daily profile = the Chromium profile with the largest History file — accumulated history
# identifies where the person lives. Never recency.

$ErrorActionPreference = 'SilentlyContinue'

# --- Daily browser ---
$progId = (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\https\UserChoice').ProgId
$families = @{
  'ChromeHTML'  = @{ family = 'chrome';  dataDir = "$env:LOCALAPPDATA\Google\Chrome\User Data";  binaries = @("$env:ProgramFiles\Google\Chrome\Application\chrome.exe", "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe", "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe") }
  'MSEdgeHTM'   = @{ family = 'edge';    dataDir = "$env:LOCALAPPDATA\Microsoft\Edge\User Data"; binaries = @("${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe", "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe", "$env:LOCALAPPDATA\Microsoft\Edge\Application\msedge.exe") }
  'FirefoxURL'  = @{ family = 'firefox' }
  'BraveHTML'   = @{ family = 'brave' }
}
$known = $null
if ($progId) {
  foreach ($key in $families.Keys) { if ($progId -like "$key*") { $known = $families[$key]; break } }
}
if (-not $known) { $known = @{ family = 'other' } }
$extensionCapable = $known.family -in @('chrome', 'edge')
$binary = $null
if ($known.binaries) { $binary = $known.binaries | Where-Object { Test-Path $_ } | Select-Object -First 1 }
$browserId = if ($progId) { $progId } else { 'unknown' }
$browser = [ordered]@{
  id                = $browserId
  family            = $known.family
  extension_capable = $extensionCapable
  binary            = $binary
}

# --- Profiles: Local State info_cache keys, ranked by History file size ---
$profiles = @()
if ($extensionCapable -and (Test-Path "$($known.dataDir)\Local State")) {
  $localState = Get-Content "$($known.dataDir)\Local State" -Raw | ConvertFrom-Json
  $cache = $localState.profile.info_cache
  if ($cache) {
    $profiles = @($cache.PSObject.Properties | ForEach-Object {
      $dir = $_.Name; $info = $_.Value
      $historyPath = Join-Path $known.dataDir (Join-Path $dir 'History')
      $bytes = 0
      if (Test-Path $historyPath) { $bytes = (Get-Item $historyPath).Length }
      $name = if ($info.gaia_name) { $info.gaia_name } elseif ($info.name) { $info.name } else { $dir }
      [ordered]@{ directory = $dir; name = $name; email = $info.user_name; history_bytes = $bytes }
    } | Sort-Object { -$_.history_bytes })
  }
}

# --- Pick: history-size winner; ask only when the top two are within 2x ---
$pick = $null
if ($profiles.Count -gt 0) {
  $top = $profiles[0]
  $second = if ($profiles.Count -gt 1) { $profiles[1] } else { $null }
  $margin = $null
  $ask = $false
  if ($second -and $second.history_bytes -gt 0) {
    $margin = [math]::Round($top.history_bytes / $second.history_bytes, 1)
    $ask = $top.history_bytes -lt (2 * $second.history_bytes)
  }
  $pick = [ordered]@{ directory = $top.directory; name = $top.name; email = $top.email; margin = $margin; ask = $ask }
}

# --- Stored pin, if one exists; an explicit override there beats the auto pick ---
$pin = $null
$pinPath = "$env:USERPROFILE\.fsbp\browser.json"
if (Test-Path $pinPath) { $pin = Get-Content $pinPath -Raw | ConvertFrom-Json }

[ordered]@{
  os              = 'windows'
  default_browser = $browser
  profiles        = $profiles
  pick            = $pick
  pin             = $pin
} | ConvertTo-Json -Depth 6
