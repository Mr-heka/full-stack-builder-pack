#!/usr/bin/env bash
# browser-connect detect (macOS) — daily browser + ranked Chromium profiles + pick, as JSON.
# Read-only: no writes, no prompts, no network. Exit 0 with JSON on stdout, always.
#
# Daily browser = the OS default handler for https (LaunchServices).
# Daily profile = the Chromium profile with the largest History file — accumulated history
# identifies where the person lives. Never recency: a rarely-used window focused two minutes
# ago wins a recency race and loses the history one.
set -uo pipefail

PLIST="$HOME/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist"
TMP_LS="$(mktemp)"
trap 'rm -f "$TMP_LS"' EXIT
if [ -f "$PLIST" ]; then
  plutil -convert json -o "$TMP_LS" "$PLIST" 2>/dev/null || printf '{}' > "$TMP_LS"
else
  printf '{}' > "$TMP_LS"
fi

PIN_PATH="$HOME/.fsbp/browser.json"

osascript -l JavaScript - "$TMP_LS" "$HOME" "$PIN_PATH" <<'JXA'
ObjC.import('Foundation')

function readFile(path) {
  try {
    const s = $.NSString.stringWithContentsOfFileEncodingError(path, $.NSUTF8StringEncoding, null)
    return (s && !s.isNil()) ? s.js : null
  } catch (e) { return null }
}
function fileSize(path) {
  try {
    const attrs = $.NSFileManager.defaultManager.attributesOfItemAtPathError(path, null)
    return (attrs && !attrs.isNil()) ? Number(attrs.objectForKey('NSFileSize').js) : 0
  } catch (e) { return 0 }
}
function exists(path) { return $.NSFileManager.defaultManager.fileExistsAtPath(path) }

function run(argv) {
  const lsJsonPath = argv[0], home = argv[1], pinPath = argv[2]

  // --- Daily browser: LaunchServices https handler; Safari is the unset default. ---
  let handlerId = 'com.apple.safari'
  try {
    const ls = JSON.parse(readFile(lsJsonPath) || '{}')
    const entry = (ls.LSHandlers || []).find(e => e.LSHandlerURLScheme === 'https' && e.LSHandlerRoleAll)
    if (entry) handlerId = String(entry.LSHandlerRoleAll).toLowerCase()
  } catch (e) {}

  const FAMILIES = {
    'com.google.chrome':        { family: 'chrome', dataDir: 'Google/Chrome',   binary: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome' },
    'com.google.chrome.beta':   { family: 'chrome', dataDir: 'Google/Chrome Beta', binary: '/Applications/Google Chrome Beta.app/Contents/MacOS/Google Chrome Beta' },
    'com.microsoft.edgemac':    { family: 'edge',   dataDir: 'Microsoft Edge',  binary: '/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge' },
    'com.apple.safari':         { family: 'safari' },
    'org.mozilla.firefox':      { family: 'firefox' },
    'com.brave.browser':        { family: 'brave' },
    'company.thebrowser.browser': { family: 'arc' },
  }
  const known = FAMILIES[handlerId] || { family: 'other' }
  const extensionCapable = known.family === 'chrome' || known.family === 'edge'
  // /Applications first, then the per-user ~/Applications install. A null binary is still
  // pinnable: rung 1 falls back to `open -b <bundle id> --args --profile-directory=...`.
  let binary = null
  if (known.binary) binary = [known.binary, home + known.binary].find(exists) || null
  const browser = {
    id: handlerId,
    family: known.family,
    extension_capable: extensionCapable,
    binary: binary,
  }

  // --- Profiles: Local State info_cache keys, ranked by History file size. ---
  let profiles = []
  if (extensionCapable) {
    const dataDir = home + '/Library/Application Support/' + known.dataDir
    try {
      const localState = JSON.parse(readFile(dataDir + '/Local State') || '{}')
      const cache = (localState.profile && localState.profile.info_cache) || {}
      profiles = Object.keys(cache).map(dir => ({
        directory: dir,
        name: cache[dir].gaia_name || cache[dir].name || dir,
        email: cache[dir].user_name || null,
        history_bytes: fileSize(dataDir + '/' + dir + '/History'),
      })).sort((a, b) => b.history_bytes - a.history_bytes)
    } catch (e) {}
  }

  // --- Pick: history-size winner; ask only when the top two are within 2x. ---
  let pick = null
  if (profiles.length > 0) {
    const top = profiles[0], second = profiles[1]
    const margin = (second && second.history_bytes > 0)
      ? Math.round((top.history_bytes / second.history_bytes) * 10) / 10
      : null
    pick = { directory: top.directory, name: top.name, email: top.email,
             margin: margin, ask: !!(second && top.history_bytes < 2 * second.history_bytes) }
  }

  // --- Stored pin, if one exists; an explicit override there beats the auto pick. ---
  let pin = null
  try { pin = JSON.parse(readFile(pinPath) || 'null') } catch (e) {}

  return JSON.stringify({ os: 'macos', default_browser: browser, profiles: profiles, pick: pick, pin: pin }, null, 2)
}
JXA
