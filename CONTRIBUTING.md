# 参与贡献

## 分支模型

- `main`：可构建、可发布的稳定状态
- `feat/*`、`fix/*`：功能与修复分支，合并前需保证 `scripts/build.sh` 通过

## 改动落在哪一层

| 层 | 位置 | 说明 |
| --- | --- | --- |
| 内核 / 端口 | `patches/0001-servo-ohos-browser.patch` 中 `components/`、`ports/` 部分 | 优先向上游 servo/servo 提 PR，减少补丁体积 |
| 应用外壳 | 补丁中 `support/openharmony/` 部分 | 主要工作区，改动频繁 |

修改流程：

```bash
./scripts/build.sh          # 首次：拉取 servo 并应用补丁
cd servo && $EDITOR support/openharmony/entry/src/main/ets/pages/Index.ets
cd .. && ./scripts/build.sh # 重新编译
# 提交前导出补丁
cd servo && git diff --binary > ../patches/0001-servo-ohos-browser.patch
```

## 提交规范

- 一次提交只做一件事，提交信息用中文或英文均可，格式：`<范围>: <说明>`，例如 `ohos: 修复标签 favicon 不刷新`
- 涉及 UI 的改动请附截图
- 不要提交 `servo/`、`hvigor-env/`、`*.hap`、`env.sh`

## 代码约定

- ArkTS：2 空格缩进；颜色走 `Index.ets` 顶部的 token 函数，不硬编码
- Rust：`cargo fmt` + `./mach fmt`，不要引入新的 `unwrap()` 到 NAPI 入口
- 任何"内核没给的能力"必须有降级路径，不能静默失败

## 上游同步

```bash
./scripts/sync-upstream.sh   # 会把补丁 rebase 到 servo/main
```

冲突解决后重新导出补丁并更新 `scripts/build.sh` 中的 `SERVO_COMMIT`。
