# VanDyke SecureCRT / SecureFX / VShell — 自动发布

每日自动检查 [VanDyke](https://www.vandyke.com) 最新版本，发现新版本时自动下载全平台安装包并发布到 [Releases](../../releases) 页面。

## 产品

| 产品 | 正式版 | Beta |
|---|---|---|
| **SecureCRT** | ✅ | ✅ |
| **SecureFX** | ✅ | ✅ |
| **VShell** | ✅ | ✅ |

## 平台

- Windows (x64)
- macOS (ARM64 / Intel)
- Linux (Ubuntu .deb)

## 运行机制

6 个独立 GitHub Actions workflow，每日 UTC 00:00-00:50 错开运行（每个使用不同 IP）：

| 时间 (UTC) | Workflow | 产品 | 渠道 |
|---|---|---|---|
| 00:00 | `securecrt-stable` | SecureCRT | 正式版 |
| 00:10 | `securefx-stable` | SecureFX | 正式版 |
| 00:20 | `vshell-stable` | VShell | 正式版 |
| 00:30 | `securecrt-beta` | SecureCRT | Beta |
| 00:40 | `securefx-beta` | SecureFX | Beta |
| 00:50 | `vshell-beta` | VShell | Beta |

**同版本同 build 的所有文件发在同一个 Release 下。**

## Copyright

Copyright (c) 2026 LOVECHEN. All rights reserved.
