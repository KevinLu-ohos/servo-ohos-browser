# 上传与协作

## 一、推到 GitHub / GitCode

先在网页上建一个**空仓库**（不要勾选初始化 README），然后：

```bash
cd servo-ohos-browser
git remote add origin git@github.com:<你的账号>/servo-ohos-browser.git   # 或 gitcode.com 的地址
git push -u origin main
```

> 仓库里没有 `servo/` 本体（1.5 GB），只有 200 KB 的补丁与脚本；任何人 clone 后执行 `./scripts/build.sh` 会自动拉取对应 commit 的 servo 并打补丁。

## 二、HAP 作为 Release 附件

HAP 约 126 MB，超过 GitHub 单文件 100 MB 限制，不能进仓库：

```bash
gh release create v0.10.72 \
  ~/Documents/servoshell-ohos/servoshell-ohos-2in1-0.10.72-unsigned.hap \
  --title "v0.10.72" --notes-file release/notes-0.10.72.md
```

GitCode：仓库 → 「发行版」→ 新建发布 → 上传同一个 HAP。

## 三、邀请协作者

- GitHub：Settings → Collaborators → Add people
- GitCode：仓库 → 成员管理 → 邀请

协作者首次参与：

```bash
git clone <仓库地址> && cd servo-ohos-browser
cp env.example.sh env.sh && $EDITOR env.sh     # 按本机 DevEco 路径调整
./scripts/setup-hvigor.sh
./scripts/build.sh                              # 首次约 10-20 分钟（含拉取 servo 与编译）
```

## 四、日常协作流

```bash
git pull --rebase                # 拉取他人改动
./scripts/build.sh               # 本地验证
git checkout -b feat/xxx
# 改 servo/support/openharmony/... 或 patches
(cd servo && git diff --binary > ../patches/0001-servo-ohos-browser.patch)
git add -A && git commit -m "feat: ..." && git push
```

改内核（`components/`、`ports/`）时同理，补丁会一并导出。

## 五、上游同步

```bash
./scripts/sync-upstream.sh       # 把补丁 rebase 到 servo/main
# 冲突解决后重新导出补丁，并更新 scripts/build.sh 里的 SERVO_COMMIT
```

## 六、CI

`.github/workflows/build.yml` 会在 macOS runner 上：安装 Rust 1.97.1 + cargo-ohos → 下载 OpenHarmony SDK → 应用补丁 → `mach build`。

CI **不打包 HAP**（hvigor 与签名材料需要本地 DevEco），只保证"代码可编译"。

## 七、许可证注意

Servo 为 MPL-2.0。本仓库的补丁与新增文件同样以 MPL-2.0 发布；修改过的上游文件需保留其许可证头。
