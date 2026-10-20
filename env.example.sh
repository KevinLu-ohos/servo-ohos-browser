#!/usr/bin/env bash
# 复制为 env.sh 后按需修改：cp env.example.sh env.sh
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DEVECO="${DEVECO_HOME:-/Applications/DevEco-Studio.app/Contents}"

# OpenHarmony SDK（DevEco 安装后自动发现；也可用 cargo-ohos 下载的 SDK）
export OHOS_SDK_NATIVE="${OHOS_SDK_NATIVE:-$DEVECO/sdk/default/openharmony/native}"
export DEVECO_SDK_HOME="${DEVECO_SDK_HOME:-$DEVECO/sdk}"
export JAVA_HOME="${JAVA_HOME:-$DEVECO/jbr/Contents/Home}"

# hvigor / node / hdc
export PATH="$DEVECO/tools/hvigor/bin:$DEVECO/tools/node/bin:$DEVECO/sdk/default/openharmony/toolchains:$HOME/.cargo/bin:$HOME/.local/bin:/opt/homebrew/bin:$PATH"

# mach 需要 uv
export PATH="$HOME/.local/bin:$PATH"

# 关键：servo 的 .cargo/config.toml 把 MACOSX_DEPLOYMENT_TARGET 设为 13.0，
# 在 macOS 26/27 + 新 Xcode 下会导致 host proc-macro dylib 被 dyld 拒绝
# （mis-aligned LINKEDIT string pool）。这里覆盖为 11.0。
export MACOSX_DEPLOYMENT_TARGET=11.0

# mach 打包需要 HVIGOR_PATH/node_modules/@ohos/hvigor
# 运行 scripts/setup-hvigor.sh 会自动创建
export HVIGOR_PATH="$ROOT/hvigor-env"

# 可选：签名材料
# export SERVO_OHOS_SIGNING_CONFIG="$ROOT/signing/signing-configs.json"
