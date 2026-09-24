#!/bin/bash
# Erzeugt die README-Mockups neu (docs/screenshots/*.png).
#
# 1. render-previews: rendert die Beispieldateien mit Loupes echten Renderern (hell + dunkel)
# 2. compose.py:      setzt jede Vorschau in ein Quick-Look-Fenster vor einen Hintergrund
# 3. Chrome headless: fotografiert jede Seite in 1,5-facher Auflösung
# 4. pngquant:        verlustarm komprimiert (falls installiert)
#
# Aufruf: Tools/ScreenshotGenerator/generate.sh
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${HERE}/../.." && pwd)"
WORK="${ROOT}/build/mockups"
OUT="${ROOT}/docs/screenshots"
CHROME="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
SCALE="${SCALE:-1.5}"

[ -x "${CHROME}" ] || { echo "Google Chrome nicht gefunden (CHROME=… setzen)" >&2; exit 1; }

rm -rf "${WORK}"
mkdir -p "${WORK}/html" "${WORK}/pages" "${OUT}"

echo "==> Rendering samples with Loupe's renderers..."
swift build -c release --package-path "${HERE}" >/dev/null
"${HERE}/.build/release/render-previews" "${WORK}/html" \
    "${HERE}/samples/package.json" \
    "${HERE}/samples/broken.json" \
    "${HERE}/samples/README.md" \
    "${HERE}/samples/server.log" \
    "${HERE}/samples/sales.tsv" \
    "${ROOT}/Sources/LoupeCore/Preview/RendererRegistry.swift" \
    "${ROOT}/Tests/Fixtures/scripts/deploy.ps1" \
    "${ROOT}/Tests/Fixtures/scripts/build.bat" \
    "${ROOT}/Tests/Fixtures/xml/01-config.xml"

echo "==> Composing window frames..."
python3 "${HERE}/compose.py" "${WORK}/html" "${WORK}/pages"

echo "==> Capturing with headless Chrome (scale ${SCALE})..."
while read -r ident width height; do
    target="${OUT}/${ident}.png"
    rm -f "${target}"
    # Eigenes Profil: sonst haengt sich Headless-Chrome an eine laufende Chrome-Instanz.
    "${CHROME}" --headless=new --disable-gpu --hide-scrollbars \
        --user-data-dir="${WORK}/chrome-profile" --no-first-run --no-default-browser-check \
        --force-device-scale-factor="${SCALE}" \
        --window-size="${width},${height}" \
        --screenshot="${target}" \
        "file://${WORK}/pages/${ident}.html" >/dev/null 2>&1 &
    pid=$!
    # Chrome beendet sich nach --screenshot nicht immer von selbst: auf die Datei
    # warten (bis 60 s), dann den Prozess selbst beenden.
    for _ in $(seq 1 120); do
        [ -s "${target}" ] && break
        kill -0 "${pid}" 2>/dev/null || break
        sleep 0.5
    done
    sleep 0.5
    kill "${pid}" 2>/dev/null || true
    wait "${pid}" 2>/dev/null || true
    [ -s "${target}" ] || { echo "Screenshot fehlgeschlagen: ${ident}" >&2; exit 1; }
    echo "    ${ident}.png"
done < "${WORK}/pages/sizes.txt"

if command -v pngquant >/dev/null; then
    echo "==> Compressing with pngquant..."
    # Nur die eben erzeugten Bilder -- fremde PNGs im Ordner bleiben unangetastet.
    while read -r ident _ _; do
        pngquant --force --skip-if-larger --quality 80-95 --ext .png "${OUT}/${ident}.png" || true
    done < "${WORK}/pages/sizes.txt"
fi

du -sh "${OUT}"
