# Servo Browser for HarmonyOS PC — 0.10.47

侧载包：`servoshell-ohos-2in1-0.10.47-unsigned.hap`（未签名，需自行签名后安装）
内核：Servo 0.7.0（含本仓库 `patches/0001-servo-ohos-browser.patch` 的 OpenHarmony 端口改动）

## 本版重点

- **修复闪退（重要）**：启动参数曾注入 `--user-agent`（servoshell 不支持该参数），
  解析失败会 `exit(1)`，导致「首装可打开、之后每次启动闪退」。现已移除该参数并让解析失败回退默认值。
- **修复全屏必现闪退**：surface 重建时会用同一 window id 再建平台窗口，现检测到重复即替换；
  resize 增加 0/异常尺寸防御。
- **中文输入**：补齐 IME 的三条文本查询回调（`getTextIndexAtCursor` / 左右文本）、
  开启 `preview_text_support` 与 `window_id`、attach 生命周期改为按焦点重建，
  修复 `keyboard_status_changed(Hidden)` 导致的输入框失焦。
- **下载管理器**：服务端文件名、唯一命名、暂停/继续/取消/重试/打开、记录持久化与「已中断」恢复、
  并发下载（同 URL 去重）。
- **界面**：工具栏/标签尺寸放大、设置页分区与左栏图标、图标随系统深浅色反色（资源限定词驱动）、
  拖动标签的液态玻璃、新标签页随窗口自适应。
- **调试与反馈页**：日志分页 + 搜索 + 复制 + 导出（带版本/设备头部）。

## 已知问题（发布说明中明确保留）

1. **中文输入**：部分站点首次点击输入框后需要再点击一次；个别站点偶发不可用。英文输入正常。
2. **下载**：功能仍在完善，**不保证下载一定成功完成**（权限、网络、需要登录态的链接、blob 4MB 上限等）。
3. 无 DRM（付费流媒体不可用）、单进程无站点隔离。

## 校验

```bash
shasum -a 256 servoshell-ohos-2in1-0.10.47-unsigned.hap
```
