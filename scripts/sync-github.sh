#!/usr/bin/env bash
# 阶段性同步：servo 工作树 → 补丁 → 提交 → 推送 GitHub
# 用法：./scripts/sync-github.sh "feat: 描述"
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVO_DIR="${SERVO_DIR:-$(cd "$ROOT/.." && pwd)/servo}"
MSG="${1:-chore: sync from local workspace}"
PATCH="$ROOT/patches/0001-servo-ohos-browser.patch"

[ -d "$SERVO_DIR/.git" ] || { echo "找不到 servo 工作树：$SERVO_DIR"; exit 1; }

echo "==> 导出补丁（含新增文件）"
git -C "$SERVO_DIR" add -N support/openharmony/entry/src/main/ets 2>/dev/null || true
git -C "$SERVO_DIR" diff --binary > "$PATCH"
echo "    $(grep -c '^diff --git' "$PATCH") 个文件，$(du -h "$PATCH" | cut -f1)"

echo "==> 提交并推送"
cd "$ROOT"
git add -A
if git diff --cached --quiet; then
  echo "    没有需要提交的改动"
else
  git -c user.name="KevinLu-ohos" -c user.email="dev@example.com" commit -q -m "$MSG"
  echo "    $(git log -1 --format='%h %s')"
fi
git push origin main
echo "==> 已同步：https://github.com/KevinLu-ohos/servo-ohos-browser"
