# 发布说明

HAP 体积约 126 MB，超过 GitHub 单文件 100 MB 限制，**不要提交进仓库**，请作为 Release 附件上传。

## GitHub

```bash
gh release create v0.10.62 \
  release/servoshell-ohos-2in1-0.10.62-unsigned.hap \
  --title "v0.10.62" \
  --notes-file release/notes-0.10.62.md
```

## GitCode

仓库页面 → 「发行版」→ 新建发布 → 上传 HAP 附件。

## 校验

```bash
shasum -a 256 -c release/SHA256SUMS
```
