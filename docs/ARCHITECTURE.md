# 架构

```
┌───────────────────────────── HAP ──────────────────────────────┐
│ ArkUI 外壳（ArkTS）                                             │
│  ├─ 标签条 / 导航栏 / Omnibox / 菜单                             │
│  ├─ 新标签页（原生 ArkUI 视图，非网页）                           │
│  ├─ 设置 / 下载 / 扩展 面板                                      │
│  └─ XComponent(SURFACE) × 标签数                                │
│            │ NAPI（napi-ohos）                                  │
│ Rust cdylib：servo 的 OpenHarmony 端口                           │
│  ├─ EGL + surfman + ANGLE(WebGL)                               │
│  ├─ Servo（单实例、多 WebView）+ SpiderMonkey                    │
│  └─ MediaKit(AVPlayer) 播放 <video>                            │
└────────────────────────────────────────────────────────────────┘
```

## 关键设计

### 1. 一个 Servo 实例承载多个标签

servo 的 Constellation 原生支持多个 WebView，OHOS 端口上 `ipc-channel` 被强制 in-process，因此不能一个标签一个进程。

`focusWebview(index, arktsIds)` 用「位置 → 窗口 id」的映射切换活动标签；重排标签时需要同步这个顺序。

### 2. 事件通道

servo 0.7 起，嵌入方事件走 `WebViewDelegate`（`ports/servoshell/running_app_state.rs`），而不是旧的 `HostTrait`。本项目的 UI 状态（标题、导航、加载、光标、favicon）全部从 delegate 转发到 NAPI：

```
WebViewDelegate::notify_* → egl::ohos::notify_* → ThreadsafeFunction → ArkTS
```

> 部分设备上 delegate 通知不稳定，因此加载状态、图标、历史都在 ArkTS 侧有自维护的兜底实现。

### 3. 历史与返回

ArkTS 为每个标签维护 `history[] + historyIndex`：

- 返回 = `goBack()` + 400ms 后校验地址，未变则 `loadURL(history[index-1])`
- 历史见底时回到「新标签页」（ArkUI 视图，不在 webview 历史里）

### 4. 下载

servo 没有下载管理器，本项目自己实现：

1. 注入脚本拦截 `<a download>` / 文件后缀 / `window.open` / `a.click()`，通过 `document.title` 回传；
2. 内核 `components/net/http_loader.rs` 检测 `Content-Disposition: attachment`，经 `net::download_hook` 上报；
3. `blob:` 通过 NAPI `evalJsResult` 分块取回 base64 再落盘（≤4MB）；
4. ArkTS 用 `@ohos.request` 下载（带 UA / Referer），默认写入 `<下载>/Servo`（`READ_WRITE_DOWNLOAD_DIRECTORY` 权限）。

### 5. 键盘输入

OHOS 的 XComponent 只给 keycode，PC 上没有软键盘兜底，因此：

- Rust 侧把可打印键码转成 `Key::Character` 事件；
- ArkTS 侧再加一层 `onKeyEvent → insertText()` 兜底；
- 新标签页直接改用原生 ArkUI 输入框，彻底绕开内核输入。
