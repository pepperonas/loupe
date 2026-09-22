#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

VERSION="${1}"
if [ -z "${VERSION}" ]; then
    VERSION="$(git -C "${ROOT_DIR}" describe --tags --exact-match 2>/dev/null || git -C "${ROOT_DIR}" describe --tags 2>/dev/null || echo "v0.1.0")"
fi

# Ensure version starts with 'v' for artifact naming consistency
if [[ "${VERSION}" != v* ]]; then
    VERSION="v${VERSION}"
fi

echo "==> Packaging Loupe release: ${VERSION}"

# 1. Build application bundle in release mode
"${SCRIPT_DIR}/build_app.sh" release

APP_BUNDLE="${ROOT_DIR}/build/Loupe.app"
RELEASE_DIR="${ROOT_DIR}/build/release"
ZIP_NAME="Loupe-${VERSION}-macOS.zip"
ZIP_PATH="${RELEASE_DIR}/${ZIP_NAME}"
SHA_FILE="${RELEASE_DIR}/SHA256SUMS.txt"

if [ ! -d "${APP_BUNDLE}" ]; then
    echo "Error: ${APP_BUNDLE} not found!" >&2
    exit 1
fi

rm -rf "${RELEASE_DIR}"
mkdir -p "${RELEASE_DIR}"

echo "==> Creating zip archive with ditto (preserving code signing & metadata)..."
ditto -c -k --keepParent "${APP_BUNDLE}" "${ZIP_PATH}"

echo "==> Generating SHA256 checksums..."
cd "${RELEASE_DIR}"
shasum -a 256 "${ZIP_NAME}" > "${SHA_FILE}"
shasum -a 256 "${ZIP_NAME}" > "${ZIP_PATH}.sha256"

echo ""
echo "✔ Release package created successfully:"
echo "  Archive:  ${ZIP_PATH} ($(du -sh "${ZIP_PATH}" | awk '{print $1}'))"
echo "  Checksum: ${SHA_FILE}"
cat "${SHA_FILE}"
echo ""
