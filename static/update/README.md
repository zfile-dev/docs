# 更新检测元数据

ZFile 后台通过 `latest.json` 检测新版本并展示更新内容。

ZFile 只有一个统一发行版本。未填写授权码时使用免费功能，填写有效授权码后启用捐赠版功能，不再维护或发布独立的开源版版本号与更新记录。

发布新版本时，应同时更新统一更新日志和 `latest.json`。`latestVersion` 使用可比较的语义版本号，不添加 `Pro` 等发行版后缀；`sections` 只放适合在后台弹窗展示的更新摘要，完整内容继续维护在更新日志页面。

仅授权后可用的功能必须写入分组的 `proItems`，普通功能写入 `items`。后台会把 `proItems` 置于同一分组最前方，并显示捐赠版图标和标签，避免免费用户误认为该能力无需授权即可使用。

当前协议版本为 `schemaVersion: 1`。修改字段结构时必须提升协议版本，并先确保已发布的 ZFile 客户端能够兼容。

## 与 Linux Native 更新清单的边界

`static/update/latest.json` 只负责后台页面展示，继续在文档项目中与更新日志一起维护：

- `title`、`summary`、`sections` 由发版内容决定。
- `items` 放通用功能，`proItems` 放需要授权的功能。
- 完整内容维护在 changelog，`latest.json` 仅保留适合后台弹窗的摘要。

Linux Native 一键更新使用独立的机器清单：

- `latest-release.properties`
- `latest-prerelease.properties`
- `latest-release.properties.sig`
- `latest-prerelease.properties.sig`

这些文件由后端 Native GitHub Actions 根据安装包自动生成、签名并上传到 Release 服务器，不在文档项目中手动维护。其中只包含版本、平台、下载地址、文件大小和 SHA-256 等安全更新信息，不包含更新说明。

安装包按通道和版本上传到隔离目录，例如 `ZFILE-PRO/stable/5.0.3/` 和
`ZFILE-PRO/prerelease/5.0.3-beta.1/`。`ZFILE-PRO/` 根目录下的安装包别名只在发布正式版时刷新，
测试版不会覆盖正式版下载文件。Actions 从后端 `pom.xml` 自动派生前端版本、Docker 标签、上传目录和清单 URL。
发布 stable 时还会校验本文件同目录下 `latest.json` 的 `latestVersion` 是否与后端版本一致，不一致会拒绝发布。

推荐发布顺序：先部署 changelog 和 `latest.json`，再运行后端 Native workflow 并发布签名机器清单。
