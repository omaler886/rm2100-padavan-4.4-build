#!/usr/bin/env bash
set -euo pipefail

PROFILE="${1:-1000mhz}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="${WORK:-$ROOT/work}"
SRC="$WORK/padavan-4.4"
OUT="$ROOT/out/$PROFILE"

case "$PROFILE" in
  1000mhz|880mhz) ;;
  *)
    echo "usage: $0 {1000mhz|880mhz}" >&2
    exit 2
    ;;
esac

UPSTREAM_URL="$(sed -n 's/^UPSTREAM_URL=//p' "$ROOT/source.lock")"
UPSTREAM_COMMIT="$(sed -n 's/^UPSTREAM_COMMIT=//p' "$ROOT/source.lock")"
JOBS="${JOBS:-$(nproc)}"
SRC_ARCHIVE="$WORK/padavan-4.4-$UPSTREAM_COMMIT.tar.gz"

if [ -z "$UPSTREAM_URL" ] || [ -z "$UPSTREAM_COMMIT" ]; then
  echo "source.lock is incomplete" >&2
  exit 1
fi

mkdir -p "$WORK" "$OUT"

if [ ! -f "$SRC_ARCHIVE" ]; then
  echo "Downloading source archive for $UPSTREAM_COMMIT"
  curl -fL --retry 3 --retry-delay 2 \
    "${UPSTREAM_URL%/}/archive/${UPSTREAM_COMMIT}.tar.gz" \
    -o "$SRC_ARCHIVE"
fi

echo "Extracting source archive"
rm -rf "$SRC"
mkdir -p "$SRC"
tar -xzf "$SRC_ARCHIVE" -C "$SRC" --strip-components=1
rm -f "$SRC_ARCHIVE"

echo "Rendering profile $PROFILE"
python3 "$ROOT/scripts/render-profile.py" \
  "$SRC/trunk/configs/templates/RM2100.config" \
  "$ROOT/profiles/common.conf" \
  "$ROOT/profiles/$PROFILE.conf" \
  "$SRC/trunk/configs/templates/RM2100.config"

echo "Preparing MIPS toolchain"
(cd "$SRC/toolchain-mipsel" && sh dl_toolchain.sh)

echo "Building RM2100 $PROFILE with $JOBS jobs"
cd "$SRC/trunk"
rm -rf images
export MAKEFLAGS="-j${JOBS}"

set +e
fakeroot ./build_firmware_modify RM2100 custom 2>&1 | tee "$OUT/build.log"
build_rc="${PIPESTATUS[0]}"
set -e
if [ "$build_rc" -ne 0 ]; then
  echo "build failed with exit code $build_rc; see $OUT/build.log" >&2
  exit "$build_rc"
fi

shopt -s nullglob
images=("$SRC/trunk/images/"*.trx)
if [ "${#images[@]}" -ne 1 ]; then
  echo "expected exactly one .trx, found ${#images[@]}" >&2
  exit 1
fi

cp "${images[0]}" "$OUT/"
cp "$SRC/trunk/.config" "$OUT/firmware.config"
if [ -f "$SRC/trunk/linux-4.4.x/.config" ]; then
  cp "$SRC/trunk/linux-4.4.x/.config" "$OUT/kernel-4.4.config"
fi

{
  echo "profile=$PROFILE"
  echo "upstream_url=$UPSTREAM_URL"
  echo "upstream_commit=$UPSTREAM_COMMIT"
  echo "host=$(hostname)"
  echo "jobs=$JOBS"
  echo "built_at=$(date -u +%FT%TZ)"
  echo "gcc=$(gcc --version | head -1)"
} > "$OUT/build-meta.txt"

"$ROOT/scripts/verify-image.sh" "$OUT"/*.trx "$OUT/kernel-4.4.config" | tee "$OUT/verify.txt"
sha256sum "$OUT"/*.trx > "$OUT/SHA256SUMS"

echo "Built:"
ls -lh "$OUT"/*.trx
cat "$OUT/SHA256SUMS"

