#!/usr/bin/env bash
# check-constraints.sh — fails on any wronglist match.
# Usage: ./ci/check-constraints.sh [scope dirs...]   (defaults below)
set -euo pipefail
cd "$(dirname "$0")/.."
if [ $# -gt 0 ]; then SCOPE=("$@"); else SCOPE=(src lib app content packs out dist); fi
existing=()
for d in "${SCOPE[@]}"; do [ -d "$d" ] && existing+=("$d"); done
if [ ${#existing[@]} -eq 0 ]; then echo "no scope dirs found (looked in: ${SCOPE[*]})"; exit 2; fi
# Strip comment lines + blanks + trailing comments/whitespace before matching
PATTERNS=$(mktemp)
sed -e 's/[[:space:]]#.*$//' -e 's/[[:space:]]*$//' evals/wronglist.txt | grep -v -e '^[[:space:]]*$' -e '^#' > "$PATTERNS" || true
if [ ! -s "$PATTERNS" ]; then echo "wronglist has no active entries"; rm -f "$PATTERNS"; exit 2; fi
if grep -rn -F -f "$PATTERNS" "${existing[@]}"; then
  echo "✗ WRONGLIST MATCHES FOUND — see above"; rm -f "$PATTERNS"; exit 1
fi
echo "✓ constraints clean"; rm -f "$PATTERNS"
