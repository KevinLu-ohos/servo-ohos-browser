# 参考源码（三套）

开发时对照用的三份源码，统一放在仓库**同级**的 `../refs/`（不入库，避免仓库膨胀）：

```
~/Documents/servoshell-ohos/
├── servo/                     ← Servo 主仓（本项目的内核基线，含全部改动）
├── refs/
│   ├── arkweb/                ← ArkWeb 组件层（openharmony/web_webview）
│   └── chromium/              ← Chromium + NWeb 适配（稀疏检出 ohos_nweb）
└── servo-ohos-browser/        ← 本项目（GitHub 仓库）
```

一键获取/更新：

```bash
./scripts/fetch-refs.sh
```

## 版本与许可

| 源码 | 位置 | 版本 | 许可 |
| --- | --- | --- | --- |
| Servo | `../servo` | `78d4d4595`（2026-10-20） | MPL-2.0 |
| ArkWeb 组件 | `../refs/arkweb` | `6bdb0f8`（2025-09-13, master） | Apache-2.0 |
| Chromium / NWeb | `../refs/chromium` | `79b56c2`（114_trunk_5.0.2-Release） | BSD-3-Clause |

> **只做参考阅读，不要整段拷贝**。MPL-2.0 允许与其它许可共存，但直接复制 BSD/Apache 代码进 MPL 文件会引入许可声明义务；需要复用时在文件头保留原始许可与来源。

## 每套看什么

### 1. ArkWeb 组件层（`refs/arkweb`）

内部是 ArkWeb 与 Chromium/NWeb 之间的**系统能力适配层**，共 40+ 个 adapter。

| 我们要做的事 | 参考路径 |
| --- | --- |
| **网页输入 / IME**（我们的痛点） | `ohos_adapter/inputmethodframework_adapter/` |
| 剪贴板、摄像头、定位、通知等能力桥接 | `ohos_adapter/{clipboard,camera,location,notification}_adapter/` |
| 显示密度、窗口与事件 | `ohos_adapter/{display_manager,event_handler}_adapter/` |
| ArkTS/ANI 侧下载 API 的形态 | `interfaces/kits/ani/webview/src/webviewcontroller/web_download_*.cpp` |
| UA 与 helper 接口 | `ohos_nweb/include/nweb_helper.h` |
| NWeb 对外接口定义 | `ohos_interface/include/ohos_nweb/` |

### 2. Chromium + NWeb（`refs/chromium`，仅 `ohos_nweb/`）

| 我们要做的事 | 参考路径 |
| --- | --- |
| **下载器实现**（Content-Disposition / 进度 / 取消） | `ohos_nweb/src/download/web_downloader.cc` |
| 下载管理器与回调 | `ohos_nweb/src/nweb_download_manager_impl.*` |
| WebView 生命周期与引擎初始化 | `ohos_nweb/src/nweb_engine_impl.*`、`nweb_delegate_adapter.*` |
| Cookie / 数据库 | `ohos_nweb/src/nweb_cookie_manager_impl.*`、`nweb_data_base_impl.*` |
| C 接口层 | `ohos_nweb/src/capi/` |

### 3. Servo 主仓（`../servo`）

本项目的内核基线。我们的改动集中在：

```
components/net/{lib.rs,http_loader.rs}        ← 附件下载信号
components/servo/lib.rs                       ← download_hook 导出
ports/servoshell/egl/ohos/mod.rs              ← 输入/光标/favicon/下载回调
ports/servoshell/running_app_state.rs         ← WebViewDelegate 事件转发
support/openharmony/                          ← ArkUI 外壳
```

## 对照开发的推荐顺序

1. **网页输入**：读 `refs/arkweb/ohos_adapter/inputmethodframework_adapter` 看 ArkWeb 如何把 IME 事件送进内核，再对照 `ports/servoshell/egl/ohos/mod.rs` 的 `on_dispatch_key_event` / `on_ime_show`。
2. **下载**：读 `refs/chromium/ohos_nweb/src/download/web_downloader.cc`，对照我们的 `components/net/download_hook` + ArkTS `performDownload`。
3. **系统能力**：需要剪贴板/摄像头/权限时，直接从 `ohos_adapter/` 找对应实现，按它的 NAPI 形状在 servo 侧加回调。
