# Full-screen PASS/FAIL banner — readable from the front of a room.
# Usage: pwsh banner.ps1 -Result PASS -Detail "16/16 CHECKS PASSED"
#        (no pwsh? powershell -ExecutionPolicy Bypass -File banner.ps1 — same arguments)
param(
    [Parameter(Mandatory)][ValidateSet('PASS', 'FAIL')][string]$Result,
    [string]$Detail = ''
)

$w = $(try { $Host.UI.RawUI.WindowSize.Width } catch { 100 })
$h = $(try { $Host.UI.RawUI.WindowSize.Height } catch { 30 })

if ($Result -eq 'PASS') { $bg = 'Green'; $fg = 'Black' } else { $bg = 'Red'; $fg = 'White' }

$art = if ($Result -eq 'PASS') {
    '#####   ###    ####   #### ',
    '#   #  #   #  #      #     ',
    '#   #  #   #  #      #     ',
    '#####  #####   ###    ###  ',
    '#      #   #      #      # ',
    '#      #   #      #      # ',
    '#      #   #  ####   ####  '
} else {
    '#####   ###   #####  #     ',
    '#      #   #    #    #     ',
    '#      #   #    #    #     ',
    '####   #####    #    #     ',
    '#      #   #    #    #     ',
    '#      #   #    #    #     ',
    '#      #   #  #####  ##### '
}

$block = [string][char]0x2588
# Double horizontally when it fits; double vertically too when the window is tall enough.
$rows = $art | ForEach-Object { $_ -replace '#', $block }
if ($w -ge 56) { $rows = $rows | ForEach-Object { $_ -replace '(.)', '$1$1' } }
if ($h -ge 24) { $rows = $rows | ForEach-Object { $_, $_ } }

$content = @('FOUNDATION CHECK', '') + @($rows) + @('')
if ($Detail) { $content += $Detail }

$pad = [Math]::Max(0, [int](($h - 1 - $content.Count) / 2))
$lines = (@('') * $pad) + $content
while ($lines.Count -lt $h - 1) { $lines += '' }

try { Clear-Host } catch { }
foreach ($line in $lines) {
    if ($line.Length -gt $w) { $line = $line.Substring(0, $w) }
    $left = [Math]::Max(0, [int](($w - $line.Length) / 2))
    $out = ((' ' * $left) + $line).PadRight($w)
    Write-Host $out -BackgroundColor $bg -ForegroundColor $fg
}
