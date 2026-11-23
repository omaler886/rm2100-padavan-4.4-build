#!/usr/bin/env bash
set -euo pipefail

IMAGE="${1:?usage: verify-image.sh IMAGE [KERNEL_CONFIG]}"
KERNEL_CONFIG="${2:-}"
WORK="$(mktemp -d)"
FAILED=0

cleanup() {
  rm -rf "$WORK"
}
trap cleanup EXIT

fail() {
  echo "FAIL: $*"
  FAILED=1
}

pass() {
  echo "OK:   $*"
}

has_path() {
  grep -qE "squashfs-root/${1}( ->|$)" "$WORK/list"
}

require_path() {
  if has_path "$1"; then
    pass "path $1"
  else
    fail "missing $1"
  fi
}

echo "== image =="
ls -lh "$IMAGE"
file "$IMAGE"

OFFSET="$(grep -abo -m1 'hsqs' "$IMAGE" | cut -d: -f1 || true)"
if [ -z "$OFFSET" ]; then
  echo "FAIL: no squashfs magic (hsqs)" >&2
  exit 1
fi
echo "squashfs_offset=$OFFSET"

tail -c +$((OFFSET + 1)) "$IMAGE" > "$WORK/squash"
unsquashfs -ll "$WORK/squash" > "$WORK/list"

echo "== required paths =="
require_path "www/Advanced_SQM.asp"
require_path "www/Advanced_DDNS_Content.asp"
require_path "www/Advanced_wireguard.asp"
require_path "www/Advanced_zerotier.asp"
require_path "www/Advanced_WAN_Content.asp"
require_path "bin/tc"
require_path "sbin/ipset"
require_path "usr/bin/aliddns.sh"
require_path "usr/bin/wg"
require_path "usr/bin/zerotier-one"
require_path "usr/lib/sqm/run.sh"
require_path "lib/modules/4.4.198/kernel/net/sched/sch_cake.ko"
require_path "bin/inadyn"

if has_path "usr/sbin/tcpdump" || has_path "usr/bin/tcpdump"; then
  pass "tcpdump binary"
else
  fail "missing tcpdump binary"
fi

if has_path "usr/sbin/sshd" || has_path "usr/sbin/dropbear"; then
  pass "SSH server"
else
  fail "missing SSH server"
fi

echo "== UI/feature strings =="
unsquashfs -cat "$WORK/squash" www/Advanced_WAN_Content.asp | grep -q 'sfe_enable' \
  && pass "WAN sfe_enable switch" || fail "WAN sfe_enable missing"
unsquashfs -cat "$WORK/squash" www/Advanced_SQM.asp | grep -q 'sqm_qdisc' \
  && pass "SQM qdisc UI" || fail "SQM qdisc UI missing"
unsquashfs -cat "$WORK/squash" www/Advanced_DDNS_Content.asp | grep -q 'CLOUDFLARE.COM' \
  && pass "DDNS Cloudflare provider" || fail "DDNS Cloudflare provider missing"
unsquashfs -cat "$WORK/squash" sbin/rc | grep -aq 'sqm_enable' \
  && pass "rc sqm_enable" || fail "rc sqm_enable missing"

if [ -n "$KERNEL_CONFIG" ] && [ -f "$KERNEL_CONFIG" ]; then
  echo "== kernel config =="
  if grep -q '^CONFIG_NET_SCH_CAKE=m' "$KERNEL_CONFIG"; then
    pass "CONFIG_NET_SCH_CAKE=m"
  else
    fail "CONFIG_NET_SCH_CAKE=m"
  fi
  if grep -q '^CONFIG_IFB=y' "$KERNEL_CONFIG"; then
    pass "CONFIG_IFB=y"
  else
    fail "CONFIG_IFB=y"
  fi
  if grep -q '^CONFIG_MT7621_OC=y' "$KERNEL_CONFIG"; then
    pass "CONFIG_MT7621_OC=y"
  elif grep -q '^# CONFIG_MT7621_OC is not set' "$KERNEL_CONFIG"; then
    pass "CONFIG_MT7621_OC disabled (880mhz profile)"
  else
    fail "CONFIG_MT7621_OC not found"
  fi
  if grep -q '^CONFIG_MT7621_CPU_FREQ="0x312"' "$KERNEL_CONFIG"; then
    pass "CONFIG_MT7621_CPU_FREQ=0x312"
  else
    fail "CONFIG_MT7621_CPU_FREQ=0x312"
  fi
fi

echo "== result =="
if [ "$FAILED" -ne 0 ]; then
  echo "STATIC VERIFY: FAIL"
  exit 1
fi
echo "STATIC VERIFY: PASS"

