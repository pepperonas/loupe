#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Build release
"${SCRIPT_DIR}/build_app.sh" release

DEST_DIR="/Applications"
if [ ! -w "${DEST_DIR}" ]; then
    DEST_DIR="${HOME}/Applications"
    mkdir -p "${DEST_DIR}"
fi

TARGET_APP="${DEST_DIR}/Loupe.app"
EXT_BUNDLE="${TARGET_APP}/Contents/PlugIns/LoupePreview.appex"
BUILD_APP="${ROOT_DIR}/build/Loupe.app"
BUILD_EXT="${BUILD_APP}/Contents/PlugIns/LoupePreview.appex"

echo "==> Installing Loupe to ${TARGET_APP}..."
rm -rf "${TARGET_APP}"
cp -R "${ROOT_DIR}/build/Loupe.app" "${TARGET_APP}"

# Resign at target destination to ensure validity
codesign --force --sign - \
    --entitlements "${ROOT_DIR}/Sources/LoupePreview/Resources/LoupePreview.entitlements" \
    --timestamp=none "${EXT_BUNDLE}"
codesign --force --sign - \
    --entitlements "${ROOT_DIR}/Sources/Loupe/Resources/Loupe.entitlements" \
    --timestamp=none "${TARGET_APP}"

echo "==> Registering with LaunchServices & pluginkit..."
# build_app.sh registers the development bundle for local testing. Remove that
# registration before registering the installed copy, otherwise Finder may pick
# either bundle (and can keep serving a stale extension after an update).
pluginkit -r "${BUILD_EXT}" || true
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -u "${BUILD_APP}" || true
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "${TARGET_APP}"
pluginkit -a "${EXT_BUNDLE}"
pluginkit -e use -i io.celox.loupe.preview

echo "==> Reloading Quick Look daemon generators..."
qlmanage -r
qlmanage -r cache

echo ""
echo "✔ Loupe installed successfully to ${TARGET_APP}!"
echo "  To test, select any .json file in Finder and press Space."
