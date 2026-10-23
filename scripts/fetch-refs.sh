#!/usr/bin/env bash
# 获取/更新参考源码（ArkWeb 组件层 + Chromium NWeb 适配）
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REFS="${REFS_DIR:-$(cd "$ROOT/.." && pwd)/refs}"
CHROMIUM_BRANCH="${CHROMIUM_BRANCH:-114_trunk_5.0.2-Release}"

mkdir -p "$REFS"

echo "==> ArkWeb 组件层 (openharmony/web_webview)"
if [ ! -d "$REFS/arkweb/.git" ]; then
  git clone --depth 1 --single-branch --branch master \
    https://gitee.com/openharmony/web_webview.git "$REFS/arkweb"
else
  git -C "$REFS/arkweb" fetch --depth 1 origin master
  git -C "$REFS/arkweb" checkout -f FETCH_HEAD
fi

echo "==> Chromium NWeb 适配 (ohos_nweb，稀疏检出)"
if [ ! -d "$REFS/chromium/.git" ]; then
  git clone --filter=blob:none --no-checkout --depth 1 --sparse \
    --branch "$CHROMIUM_BRANCH" \
    https://github.com/openharmony-tpc/chromium_src.git "$REFS/chromium"
  git -C "$REFS/chromium" sparse-checkout set ohos_nweb
else
  git -C "$REFS/chromium" fetch --depth 1 origin "$CHROMIUM_BRANCH"
  git -C "$REFS/chromium" checkout -f FETCH_HEAD
fi
git -C "$REFS/chromium" checkout -f

echo
echo "完成："
du -sh "$REFS/arkweb" "$REFS/chromium" 2>/dev/null || true
