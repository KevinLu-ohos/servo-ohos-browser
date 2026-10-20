#!/usr/bin/env bash
# 把补丁 rebase 到 servo 上游最新提交
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVO_DIR="${SERVO_DIR:-$ROOT/servo}"
cd "$SERVO_DIR"

git fetch origin main
BASE=$(git rev-parse HEAD)
git checkout -q -B ohos-work origin/main
if git apply --3way "$ROOT/patches/0001-servo-ohos-browser.patch"; then
  echo "==> patch applied cleanly on $(git rev-parse --short HEAD)"
  echo "    new pin: $(git rev-parse HEAD)"
  echo "    请更新 scripts/build.sh 里的 SERVO_COMMIT 与 patches/"
else
  echo "!! 冲突，请手工解决后：git diff --binary > $ROOT/patches/0001-servo-ohos-browser.patch"
  exit 1
fi
