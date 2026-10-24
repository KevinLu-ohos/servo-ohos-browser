# Servo Browser for HarmonyOS PC

基于 [Servo](https://github.com/servo/servo) 内核的鸿蒙电脑（HarmonyOS PC / 2in1）浏览器。
浏览器外壳用 ArkUI 重写，内核运行在 Rust + OpenHarmony 端口上。

> 状态：自用 / 内测级（当前版本 **0.10.62**）。已能在鸿蒙 PC 上日常浏览，但**不适合作为面向公众的产品**——
> 中文输入在部分站点仍不稳定，下载链路仍在完善，详见「已知问题」。

## 特性

- **多标签**：新建 / 关闭 / 切换 / 拖拽排序，关闭最后一个标签回到新标签页
- **新标签页**：Servo 环形标记 + 搜索/网址输入（原生 ArkUI 输入，不依赖内核键盘）
- **地址栏**：搜索引擎联想、https 锁标识、历史前进后退
- **书签**：地址栏星标一键收藏，书签栏可开关，面板内可搜索与删除
- **历史**：按天分组、搜索、单条删除与二次确认清空，新标签页展示「最近访问」磁贴
- **下载**：网络层识别 `Content-Disposition` 与不可渲染类型，文件名取自服务端（RFC 5987 优先）；静默保存到 `下载/Servo`；支持暂停/继续/取消/重试/打开，记录持久化、重启后标记为「已中断」可重试；显示总大小 / 已下载 / 实时速率
- **调试与反馈**：内置日志环形缓冲（引擎 + 界面日志），可分页查看、关键字搜索、复制与导出到下载目录，导出文件自带版本/设备/系统/UA 头部
- **站点图标**：内核 favicon → 页面 `<link rel=icon>` → `/favicon.ico`（自动解析 ICO 内嵌 PNG）三级回退
- **User-Agent**：内置 Servo 原版 / 鸿蒙 PC / Windows / Chrome 158 等预置，支持自定义，**切换即时生效不需要重启**
- **设置**：外观（含主题缩略图）、User-Agent、搜索引擎、启动时（主页可手填）、下载内容、扩展（用户脚本）、重置、关于
- **沉浸式外观**：API 26 沉浸材质 + 半透明工具栏 + 随环境光调整；图标颜色走资源限定词，随系统深浅色自动反色，**网页的 `prefers-color-scheme` 同步跟随系统**

## 已知问题

| 问题 | 现状 |
| --- | --- |
| **中文输入不稳定** | 原生 IME 客户端（`OH_InputMethodController_Attach`）已接通，但**部分站点首次点击输入框后需要再点一次**中文才能输入；个别站点（如百度首页）偶发完全无法输入。英文输入不受影响 |
| **下载无法保证完成** | 下载管理器仍在完善。依赖系统 `request` 服务与「下载目录」权限，权限被拒或网络中断时可能落到应用沙箱；`blob:` 下载受 4MB 限制；大文件、需要登录态的链接成功率不保证 |
| 无 DRM、单进程、部分站点兼容性 | 见下方「已知限制」 |

## 已知限制

| 限制 | 原因 |
| --- | --- |
| 无 DRM（付费流媒体不可用） | Servo 没有 Widevine/CDM |
| 单进程、无站点隔离 | OpenHarmony 端口上 `ipc-channel` 被强制 in-process |
| `blob:` 下载 ≤ 4MB | 需要把数据从页面内存搬到原生侧 |
| 部分站点兼容性问题 | Servo 的 Web 平台实现仍在完善 |

## 构建要求

- macOS（Apple Silicon 已验证）+ Xcode 命令行工具
- [DevEco Studio](https://developer.huawei.com/consumer/cn/deveco-studio)（提供 OpenHarmony SDK），或让 `cargo-ohos` 自动下载 SDK
- Rust **1.97.1**（`rust-toolchain.toml` 已固定）
- Node 18+、JDK 21+（DevEco 自带）

## 快速开始

```bash
# 1) 准备环境变量（首次执行会探测 DevEco 路径）
cp env.example.sh env.sh && $EDITOR env.sh

# 2) 一键：拉取指定 commit 的 servo → 应用补丁 → 编译
./scripts/build.sh

# 3) 打包（需要签名材料，见下）
./scripts/package.sh
```

产物：

```
servo/target/openharmony/<target>/release/entry/build/harmonyos/outputs/default/*.hap
```

## 签名（安装到真机必需）

鸿蒙电脑只接受华为 CBG 证书链签发的 profile。首次准备：

1. DevEco Studio 打开 `servo/support/openharmony`；
2. `File > Project Structure > Signing Configs` 勾选 **Automatically generate signature**（登录华为账号，设备已连接）；
3. 把 `~/.ohos/config/` 下的 `.p12/.cer/.p7b` 复制到 `signing/`，并写 `signing/signing-configs.json`（字段见 `support/openharmony/hvigorfile.ts`）；
4. `export SERVO_OHOS_SIGNING_CONFIG=$PWD/signing/signing-configs.json` 后再执行 `./scripts/package.sh`。

## 目录结构

```
patches/                 对 servo 上游的补丁（内核 + 应用层）
scripts/build.sh         拉取上游、应用补丁、编译
scripts/package.sh       打包 HAP
scripts/sync-upstream.sh 同步 servo 上游
docs/ARCHITECTURE.md     架构与实现要点
docs/ROADMAP.md          后续计划
release/                 发布说明与校验和（HAP 放 Releases）
```

## 参与协作

见 [CONTRIBUTING.md](CONTRIBUTING.md)。核心原则：

1. 内核层改动尽量以 PR 形式提给 [servo/servo](https://github.com/servo/servo)，减少补丁体积；
2. 应用层（ArkTS）改动直接在本仓库迭代；
3. 上游升级用 `scripts/sync-upstream.sh`，冲突在 `patches/` 里解决。

## 许可证

MPL-2.0，与 Servo 上游一致。见 [LICENSE](LICENSE)。
