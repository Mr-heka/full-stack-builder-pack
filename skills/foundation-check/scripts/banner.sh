#!/usr/bin/env bash
# Full-screen PASS/FAIL banner — readable from the front of a room.
# Usage: bash banner.sh PASS "16/16 CHECKS PASSED"
set -euo pipefail

RESULT="${1:?usage: banner.sh PASS|FAIL [detail]}"
DETAIL="${2:-}"

case "$RESULT" in
  PASS|FAIL) ;;
  *) echo "usage: banner.sh PASS|FAIL [detail]" >&2; exit 2 ;;
esac

COLS=$(tput cols 2>/dev/null || echo 100)
ROWS=$(tput lines 2>/dev/null || echo 30)

if [ "$RESULT" = "PASS" ]; then
  COLOR='\033[42;30m' # green background, black text
  ART=(
    '#####   ###    ####   #### '
    '#   #  #   #  #      #     '
    '#   #  #   #  #      #     '
    '#####  #####   ###    ###  '
    '#      #   #      #      # '
    '#      #   #      #      # '
    '#      #   #  ####   ####  '
  )
else
  COLOR='\033[41;97m' # red background, white text
  ART=(
    '#####   ###   #####  #     '
    '#      #   #    #    #     '
    '#      #   #    #    #     '
    '####   #####    #    #     '
    '#      #   #    #    #     '
    '#      #   #    #    #     '
    '#      #   #  #####  ##### '
  )
fi
RESET='\033[0m'

# All widening and truncation happens while lines are still ASCII; the multibyte █
# is substituted last — byte-wise locales corrupt it in any earlier step.
LINES_OUT=("FOUNDATION CHECK" "")
for row in "${ART[@]}"; do
  if [ "$COLS" -ge 56 ]; then
    wide=$(printf '%s' "$row" | sed 's/./&&/g') # double horizontally when it fits
  else
    wide="$row" # narrow terminal: single width keeps all four letters visible
  fi
  wide="${wide:0:COLS}"
  LINES_OUT+=("$wide")
  if [ "$ROWS" -ge 24 ]; then LINES_OUT+=("$wide"); fi # double vertically when tall enough
done
LINES_OUT+=("")
if [ -n "$DETAIL" ]; then LINES_OUT+=("${DETAIL:0:COLS}"); fi

PAD=$(( (ROWS - 1 - ${#LINES_OUT[@]}) / 2 ))
[ "$PAD" -lt 0 ] && PAD=0

clear 2>/dev/null || printf '\033[2J\033[H'
total=0
for ((i = 0; i < PAD; i++)); do
  printf "${COLOR}%*s${RESET}\n" "$COLS" ""
  total=$((total + 1))
done
for line in "${LINES_OUT[@]}"; do
  line="${line:0:COLS}"
  len=${#line}
  left=$(( (COLS - len) / 2 ))
  [ "$left" -lt 0 ] && left=0
  right=$(( COLS - left - len ))
  [ "$right" -lt 0 ] && right=0
  printf "${COLOR}%*s%s%*s${RESET}\n" "$left" "" "${line//'#'/█}" "$right" ""
  total=$((total + 1))
done
while [ "$total" -lt $((ROWS - 1)) ]; do
  printf "${COLOR}%*s${RESET}\n" "$COLS" ""
  total=$((total + 1))
done
