#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVO_COMMIT="981beee7c830671a7d6f7612f16ffdeaf1a900de"
SERVO_DIR="${SERVO_DIR:-$ROOT/servo}"
PATCH="$ROOT/patches/0001-servo-ohos-browser.patch"
JOBS="${JOBS:-$( (sysctl -n hw.ncpu 2>/dev/null || nproc) )}"

[ -f "$ROOT/env.sh" ] && source "$ROOT/env.sh"

if [ ! -d "$SERVO_DIR/.git" ]; then
  if [ ! -d "$SERVO_DIR" ]; then
    echo "==> cloning servo (shallow)"
    git clone --filter=blob:none https://github.com/servo/servo.git "$SERVO_DIR"
  else
    # 目录存在但没有 .git：这是 CI 缓存恢复出来的残留。actions/cache 只缓存了
    # servo/target（见 .github/workflows/build.yml 的 Cache 步骤），所以恢复后
    # $SERVO_DIR 里只有 target/、没有 .git。这种状态下不能直接
    # `git clone ... "$SERVO_DIR"`，git 会以
    # "destination path already exists and is not an empty directory" 失败。
    # 因此先克隆到临时目录，把残留里的 target/ 搬进新克隆（保住 cargo 缓存的
    # 意义），再删掉残留目录，最后把临时克隆改名成 $SERVO_DIR。
    clone_tmp="$SERVO_DIR.clone.$$"
    echo "==> $SERVO_DIR has no .git (cache residue); cloning into $clone_tmp"
    (
      # 无论成功还是失败都要清掉临时目录：subshell 退出时 trap 必定执行，
      # 已经 mv 走的路径则因 [ -d ] 判断为假而不动。
      trap 'if [ -d "$clone_tmp" ]; then rm -rf -- "$clone_tmp"; fi' EXIT
      git clone --filter=blob:none https://github.com/servo/servo.git "$clone_tmp"

      if [ -d "$SERVO_DIR/target" ]; then
        echo "==> keeping cached target/ from the residue"
        mv "$SERVO_DIR/target" "$clone_tmp/target"
      fi

      # 只删除“确认没有 .git”的残留目录，真正的仓库不会被碰。
      if [ -d "$SERVO_DIR" ] && [ ! -d "$SERVO_DIR/.git" ]; then
        rm -rf -- "$SERVO_DIR"
      fi
      mv "$clone_tmp" "$SERVO_DIR"
    )
  fi
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
set +e
./mach build --ohos --release --flavor=harmonyos -j "$JOBS"
BUILD_STATUS=$?
set -e
if [ "$BUILD_STATUS" -ne 0 ]; then
  # CI 上没装 DevEco，hvigor 校验 DEVECO_SDK_HOME 时必然失败（缺少 DevEco 的
  # SDK 元数据）。只要引擎本身编出来了，就把这次构建视为“编译通过”，
  # HAP 由本地 DevEco 环境打包。
  if [ "${ALLOW_PACKAGE_FAILURE:-0}" = "1" ] && \
     [ -f target/aarch64-unknown-linux-ohos/release/libservoshell.so ]; then
    echo "::warning::HAP packaging failed (hvigor needs a DevEco SDK layout); engine built successfully"
    echo "==> engine artifact: target/aarch64-unknown-linux-ohos/release/libservoshell.so"
    exit 0
  fi
  exit "$BUILD_STATUS"
fi

echo "==> done"
find target/openharmony -name "*.hap" -maxdepth 8 2>/dev/null || true
