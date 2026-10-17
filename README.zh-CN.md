<p align="center"><img src="docs/assets/popdeck-logo.png" width="128" alt="PopDeck"></p>
<h1 align="center">PopDeck</h1>

[官网](https://popdeck.pages.dev/) · [English](README.md)

原生 macOS 圆形快捷启动器，使用 SwiftUI 和 AppKit 构建。此仓库提供可独立构建的**单圈免费版源码**；PRO 的多圈、分组、扇形命令集、激活模块及相关测试和资源位于仓库外的私有源码覆盖层，不属于公开源码。

免费版支持应用、文件、文件夹、网址和单条 Shell 命令；命令可编辑，支持静默运行或打开终端。支持图标颜色、Emoji、文字显示、弧形排版、扇形宽度、面板大小、音效、快捷键和开机启动。macOS 26 及以上使用系统原生 Liquid Glass，旧系统回退毛玻璃。

PRO 计划为 ¥6 一次性个人永久授权，包含后续更新，允许本人多台 Mac 使用。本轮 PRO 仅在独立测试版验证，尚未发布。公开源码中的 PRO 角标和说明仅用于展示权益，不含高级功能实现或授权验证代码。

## 构建与测试

需要 macOS 14+、Xcode 26+ 或对应 Swift 工具链。

```sh
swift build
./scripts/test-edition.sh free
POPDECK_EDITION=free ./scripts/run-app.sh debug
```

`swift build` 和 `swift test` 默认只读取公开免费源码。运行脚本仅构建、签名并启动 `.build/PopDeck Dev.app`，不安装或覆盖 `/Applications/PopDeck.app`。没有本地私有配置的公开克隆中，直接运行 `./scripts/run-app.sh debug` 也会使用免费版。

命令通过 `/bin/zsh -lc` 执行，默认工作目录为用户主目录。可保存多行、管道及重定向；静默模式不提供交互输入，需要交互时选择终端执行。

免费源码版会将不支持的配置项作为不可执行占位保留，并原样保留未知字段；其他圆环的偏好键不会被修改。恢复默认、主动删除等操作仍按用户选择生效。源码版不提供 PRO 激活；授权文件与面板偏好独立，切换构建不会删除已有授权。

## 公开源码边界

```sh
python3 scripts/audit-public-source.py --history
python3 scripts/export-public-source.py
```

导出位于 `.build/public-source`，仅包含白名单中的免费源码、测试、文档和构建脚本，附 SHA-256 清单。不包含 `.git`、本地配置、私有覆盖层、构建缓存、发码工具、私钥、账本或激活凭证。已存在的导出目录不会被覆盖。

[源码边界与本地 PRO 构建](docs/source-boundaries.md) · [独立测试版说明](docs/development-builds.md)

## License

公开免费源码继续采用 [MIT License](LICENSE)。已公开版本的授权保持有效。仓库外的未公开 PRO 实现不属于本次公开源码分发。
