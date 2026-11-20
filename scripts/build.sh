#!/usr/bin/env bash
# Builds one Choutes Project kernel with linux-tkg.
#   scripts/build.sh BUILD [OUT]
#     BUILD  v3 or lts-v1 (a file in builds/)
#     OUT    folder for the packages (default: out/BUILD)
# Runs as a normal user on Arch Linux with base-devel, git, clang, llvm, lld, and the other
# packages that linux-tkg lists. The build machine's own processor never matters: every build
# has a fixed target (builds/*.cfg), and scripts/verify-config.sh fails on anything else.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD="${1:?usage: scripts/build.sh v3|lts-v1 [OUT]}"
OUT="${2:-$ROOT/out/$BUILD}"
TKG_COMMIT="$(cat "$ROOT/TKG_COMMIT")"
PKGREL="${PKGREL:-1}"
[ -f "$ROOT/builds/$BUILD.cfg" ] || { echo "unknown build: $BUILD" >&2; exit 2; }
[ "$(id -u)" -ne 0 ] || { echo "run as a normal user (makepkg)" >&2; exit 2; }

WORK="$ROOT/work/$BUILD"
rm -rf "$WORK"
mkdir -p "$WORK" "$OUT"
git clone -q https://github.com/Frogging-Family/linux-tkg.git "$WORK/linux-tkg"
git -C "$WORK/linux-tkg" checkout -q "$TKG_COMMIT"
cd "$WORK/linux-tkg"

# One settings file for this build: the shared settings, then the build's own.
cat "$ROOT/builds/common.cfg" "$ROOT/builds/$BUILD.cfg" > "$WORK/choutes.cfg"
sed -i "s|^_EXT_CONFIG_PATH=.*|_EXT_CONFIG_PATH=\"$WORK/choutes.cfg\"|" customization.cfg
grep -q "^_EXT_CONFIG_PATH=\"$WORK/choutes.cfg\"" customization.cfg
cp "$ROOT"/fragments/*.myfrag .
# Our own release number of the package.
sed -i "s/^pkgrel=.*/pkgrel=$PKGREL/" PKGBUILD

PKGDEST="$OUT" makepkg -s --noconfirm --skippgpcheck --nosign </dev/null
cp kernelconfig.new "$OUT/config-$BUILD"
cp "$WORK/choutes.cfg" "$OUT/choutes-$BUILD.cfg"
[ -d logs ] && tar -C logs -czf "$OUT/logs-$BUILD.tar.gz" .
"$ROOT/scripts/verify-config.sh" "$BUILD" "$OUT"
