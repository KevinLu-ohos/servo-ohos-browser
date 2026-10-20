#!/usr/bin/env bash
# 让 mach 能找到 hvigor：<HVIGOR_PATH>/node_modules/@ohos/hvigor/bin/hvigor.js
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[ -f "$ROOT/env.sh" ] && source "$ROOT/env.sh"
DEVECO="${DEVECO_HOME:-/Applications/DevEco-Studio.app/Contents}"
mkdir -p "$ROOT/hvigor-env/node_modules/@ohos"
ln -sfn "$DEVECO/tools/hvigor/hvigor" "$ROOT/hvigor-env/node_modules/@ohos/hvigor"
ln -sfn "$DEVECO/tools/hvigor/hvigor-ohos-plugin" "$ROOT/hvigor-env/node_modules/@ohos/hvigor-ohos-plugin"
echo "hvigor linked at $ROOT/hvigor-env"
