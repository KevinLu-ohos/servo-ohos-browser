#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVO_COMMIT="78d4d459569a810ed5c49612eab992f1bd476f69"
SERVO_DIR="${SERVO_DIR:-$ROOT/servo}"
PATCH="$ROOT/patches/0001-servo-ohos-browser.patch"
JOBS="${JOBS:-$( (sysctl -n hw.ncpu 2>/dev/null || nproc) )}"

[ -f "$ROOT/env.sh" ] && source "$ROOT/env.sh"

if [ ! -d "$SERVO_DIR/.git" ]; then
  echo "==> cloning servo (shallow)"
  git clone --filter=blob:none https://github.com/servo/servo.git "$SERVO_DIR"
fi

cd "$SERVO_DIR"
if ! git cat-file -e "$SERVO_COMMIT^{commit}" 2>/dev/null; then
  echo "==> fetching pinned commit $SERVO_COMMIT"
  git fetch origin "$SERVO_COMMIT" || git fetch --unshallow
fi
git checkout -q "$SERVO_COMMIT"

echo "==> applying patch"
git checkout -q -- .
# 浅克隆（--filter=blob:none）里没有历史 blob，`--3way` 会报
# "repository lacks the necessary blob"；补丁是针对固定 commit 生成的，
# 先直接 apply，失败再退回三方合并。
if ! git apply "$PATCH"; then
  echo "    direct apply failed, retrying with --3way"
  git apply --3way "$PATCH"
fi

echo "==> bootstrap (cargo-ohos / ohos-test-runner)"
./mach bootstrap --ohos --skip-platform --skip-nextest --yes

echo "==> building (release, -j $JOBS)"
./mach build --ohos --release --flavor=harmonyos -j "$JOBS"

echo "==> done"
find target/openharmony -name "*.hap" -maxdepth 8 2>/dev/null || true
