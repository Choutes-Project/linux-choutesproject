#!/usr/bin/env bash
# Runs inside the archlinux:base-devel container of the GitHub workflow (as root): prepares a
# build user and the Arch repositories at the date of the current Choutes Project version, then
# builds with scripts/build.sh as that user.
#   scripts/ci-inside.sh BUILD
set -euo pipefail
BUILD="$1"
ROOT=/src
SNAPSHOT="$(cat "$ROOT/SNAPSHOT")"
# The same Arch packages as the users have (the fixed date of Choutes Project): the kernel and
# the DKMS modules on the users' computers are then built with the same Clang.
echo "Server = https://archive.archlinux.org/repos/$SNAPSHOT/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist
sed -i 's/^#\?ParallelDownloads.*/ParallelDownloads = 5/' /etc/pacman.conf
pacman-key --init >/dev/null
pacman-key --populate archlinux >/dev/null
pacman -Syyuu --noconfirm --needed archlinux-keyring >/dev/null
pacman -S --noconfirm --needed base-devel git sudo bc cpio gettext libelf pahole perl python tar xxhash xz zstd \
  openssl clang llvm lld rust rust-bindgen rust-src libarchive >/dev/null
useradd -m builder
echo "builder ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/builder
chown -R builder "$ROOT"
sudo -u builder env PKGREL="${PKGREL:-1}" HOME=/home/builder "$ROOT/scripts/build.sh" "$BUILD" "$ROOT/out/$BUILD"
