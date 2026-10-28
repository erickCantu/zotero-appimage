#!/usr/bin/env bash

set -euo pipefail

APP=zotero
ARCH=x86_64
REPO_OWNER="erickCantu"
REPO_NAME="zotero-appimage"

# -- 1. Prepare the upstream archive
TARBALL="$(find . -maxdepth 1 -type f -name '*.tar.xz' -print -quit)"
[ -n "$TARBALL" ] || { echo "No upstream .tar.xz archive found" >&2; exit 1; }
CLEAN="${TARBALL##*/}"
CLEAN="${CLEAN#Zotero-}"
CLEAN="${CLEAN%_linux-x86_64.tar.xz}"

TOPDIR="$(tar tf "$TARBALL" | head -n1 | cut -d/ -f1)"
[ -n "$TOPDIR" ] || { echo "Could not determine top-level directory" >&2; exit 1; }

# -- 2. Download and verify a pinned appimagetool release
TOOL_URL="https://github.com/AppImage/appimagetool/releases/download/1.9.1/appimagetool-x86_64.AppImage"
TOOL_SHA="ed4ce84f0d9caff66f50bcca6ff6f35aae54ce8135408b3fa33abfc3cb384eb0"
[[ "$TOOL_URL" =~ ^https://github\.com/AppImage/appimagetool/releases/download/1\.[0-9]+\.[0-9]+/appimagetool-x86_64\.AppImage$ ]] ||
  { echo "Invalid appimagetool URL" >&2; exit 1; }
[[ "$TOOL_SHA" =~ ^[[:xdigit:]]{64}$ ]] ||
  { echo "Invalid appimagetool SHA-256" >&2; exit 1; }
curl -fsSL "$TOOL_URL" -o appimagetool-x86_64.AppImage
printf '%s  %s\n' "$TOOL_SHA" appimagetool-x86_64.AppImage | sha256sum -c -
chmod +x appimagetool-x86_64.AppImage

# -- 3. Assemble the AppDir
rm -rf "$APP.AppDir"
mkdir -p "$APP.AppDir/usr/share/icons/hicolor"
tar xf "$TARBALL"
[ -d "./$TOPDIR" ] || { echo "Archive does not contain ./$TOPDIR/" >&2; exit 1; }
cp -a "./$TOPDIR"/. "$APP.AppDir/usr/"
touch "$APP.AppDir/is_packaged_app"

ICON_SRC="$APP.AppDir/usr/icons/icon128.png"
[ -f "$ICON_SRC" ] || { echo "Bundled icon not found: $ICON_SRC" >&2; exit 1; }
cp "$ICON_SRC" "$APP.AppDir/.DirIcon"
cp "$ICON_SRC" "$APP.AppDir/$APP.png"
mkdir -p "$APP.AppDir/usr/share/icons/hicolor/128x128/apps"
cp "$ICON_SRC" "$APP.AppDir/usr/share/icons/hicolor/128x128/apps/zotero.png"

cat > "$APP.AppDir/zotero.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Zotero
GenericName=Reference Manager
Comment=Download ideas, organize your research, and collaborate on projects
Exec=zotero %u
Icon=zotero
Terminal=false
Categories=Office;
MimeType=x-scheme-handler/zotero;text/x-research-info-systems;application/x-research-info-systems;text/ris;application/x-endnote-refer;application/mods+xml;application/rdf+xml;application/x-bibtex;text/x-bibtex;application/marc;application/vnd.citationstyles.style+xml
X-GNOME-SingleWindow=true
StartupNotify=true
EOF

cat > "$APP.AppDir/AppRun" << 'EOF'
#!/bin/sh
HERE="$(dirname "$(readlink -f "${0}")")"
exec "${HERE}/usr/zotero" "$@"
EOF
chmod +x "$APP.AppDir/AppRun"

# -- 4. Package creation
mkdir -p dist
OUTPUT="dist/Zotero-${CLEAN}-x86_64.AppImage"
ARCH=x86_64 ./appimagetool-x86_64.AppImage \
  -u "gh-releases-zsync|${REPO_OWNER}|${REPO_NAME}|latest|Zotero-*-x86_64.AppImage.zsync" \
  "$APP.AppDir" \
  "$OUTPUT"

EXPECTED_ZSYNC="${OUTPUT}.zsync"
if [ ! -f "$EXPECTED_ZSYNC" ]; then
  for candidate in \
    "$(basename "$OUTPUT").zsync" \
    "$(basename "${OUTPUT%.AppImage}").zsync"
  do
    if [ -f "$candidate" ]; then
      mv -f "$candidate" "$EXPECTED_ZSYNC"
      break
    fi
  done
fi

echo "Build: $OUTPUT"