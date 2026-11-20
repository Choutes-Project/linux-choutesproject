#!/usr/bin/env bash
# Fails when a built kernel is not what Choutes Project promises.
#   scripts/verify-config.sh BUILD OUT
# Checks the kernel configuration (EEVDF, 1000 Hz, full preemption, Clang ThinLTO, sched-ext,
# NTsync, MGLRU, BBR) and the processor target written into the Makefile of the headers package:
# exactly the target of the build, never "native" and never another level.
set -uo pipefail
BUILD="${1:?usage: verify-config.sh BUILD OUT}"
OUT="${2:?usage: verify-config.sh BUILD OUT}"
cfg="$OUT/config-$BUILD"
fail=0
want() { grep -qx "$1" "$cfg" && echo "ok    $1" || { echo "FAIL  $1"; fail=1; }; }
case "$BUILD" in
  v3) march="x86-64-v3" ;;
  lts-v1) march="x86-64" ;;
  *) echo "unknown build: $BUILD"; exit 2 ;;
esac
[ -f "$cfg" ] || { echo "FAIL  no configuration $cfg"; exit 1; }
want "CONFIG_CC_IS_CLANG=y"
want "CONFIG_LTO_CLANG_THIN=y"
want "CONFIG_HZ_1000=y"
want "CONFIG_HZ=1000"
want "CONFIG_PREEMPT=y"
want "CONFIG_SCHED_CLASS_EXT=y"
want "CONFIG_NTSYNC=m"
want "CONFIG_LRU_GEN=y"
want "CONFIG_LRU_GEN_ENABLED=y"
want "CONFIG_TCP_CONG_BBR=y"
want "CONFIG_DEFAULT_TCP_CONG=\"bbr\""
grep -q "^CONFIG_SCHED_BORE=y\|^CONFIG_SCHED_ALT=y\|^CONFIG_SCHED_PDS=y\|^CONFIG_SCHED_BMQ=y" "$cfg" \
  && { echo "FAIL  another scheduler than EEVDF"; fail=1; } || echo "ok    EEVDF (no other scheduler)"
# NR_CPUS: the default of the kernel configuration, never the cores of the build machine (at least 64).
ncpus="$(sed -n 's/^CONFIG_NR_CPUS=//p' "$cfg")"
[ -n "$ncpus" ] && [ "$ncpus" -ge 64 ] && echo "ok    CONFIG_NR_CPUS=$ncpus" || { echo "FAIL  CONFIG_NR_CPUS is ${ncpus:-missing}"; fail=1; }
grep -q '^CONFIG_CMDLINE=""$\|^# CONFIG_CMDLINE_BOOL is not set' "$cfg" && echo "ok    no built-in command line" \
  || { echo "FAIL  a built-in kernel command line"; fail=1; }

# The processor target in the Makefile of the headers (also used by DKMS).
headers="$(ls "$OUT"/*-headers-*.pkg.tar.zst 2>/dev/null | head -n 1)"
if [ -z "$headers" ]; then
  echo "FAIL  no headers package"; fail=1
else
  flags="$(bsdtar -xOf "$headers" --include='usr/lib/modules/*/build/Makefile' 2>/dev/null | grep -E '^KBUILD_C(PP)?FLAGS \+= -march=' | sort -u)"
  echo "$flags" | sed 's/^/      /'
  if echo "$flags" | grep -q "native"; then echo "FAIL  native target"; fail=1; fi
  others="$(echo "$flags" | grep -v -- "-march=$march\$" || true)"
  if [ -z "$flags" ] || [ -n "$others" ]; then echo "FAIL  the target is not exactly -march=$march"; fail=1
  else echo "ok    -march=$march only"; fi
fi
grep -rq "native" "$OUT/choutes-$BUILD.cfg" && { echo "FAIL  native in the settings"; fail=1; }
[ "$fail" -eq 0 ] && echo "VERIFIED: $BUILD" || echo "NOT VERIFIED: $BUILD"
exit "$fail"
