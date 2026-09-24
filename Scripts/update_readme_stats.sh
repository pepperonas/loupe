#!/bin/bash
# Aktualisiert die Test- und Codezeilen-Badges in README.md und README.de.md.
# Die Testzahl stammt aus einem echten Lauf der Suite -- der Docs-Sync-Test
# (DocsSyncTests.testTestBadgeMatchesTheSuite) prüft, dass sie stimmt.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

# Die Suite darf hier rot sein (z. B. genau wegen des veralteten Badges) -- die
# Gesamtzahl steht auch in "X of N tests failed". Daher `|| true` gegen pipefail.
TESTS=$( { swift run LoupeTests 2>&1 || true; } | sed 's/\x1b\[[0-9;]*m//g' \
    | sed -nE 's/.*(All|of) ([0-9]+) (unit tests passed|tests failed).*/\2/p' | tail -1)
[ -n "${TESTS}" ] || { echo "Testzahl nicht ermittelbar" >&2; exit 1; }
LOC=$(find Sources -name '*.swift' -print0 | xargs -0 cat | grep -cv '^[[:space:]]*$')
LOC_FMT_EN=$(printf "%'d" "${LOC}" 2>/dev/null | sed 's/\./,/g')
LOC_FMT_DE=$(echo "${LOC_FMT_EN}" | sed 's/,/./g')

sed -i '' -E "s#badge/Tests-[0-9]+%20#badge/Tests-${TESTS}%20#" README.md README.de.md
sed -i '' -E "s#badge/Swift%20LoC-[0-9.,%2C]+-#badge/Swift%20LoC-${LOC_FMT_EN//,/%2C}-#" README.md
sed -i '' -E "s#badge/Swift%20LoC-[0-9.,%2C]+-#badge/Swift%20LoC-${LOC_FMT_DE}-#" README.de.md
echo "Tests: ${TESTS} · Swift LoC (ohne Leerzeilen): ${LOC}"
