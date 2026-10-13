# 受控 Fork 与镜像台账（TDD §4.7）

本文件登记 `thirdparty` 域内受控 Fork 的同步状态、改动摘要与**镜像**关系。

**结构（2026-10-14 用户拍板）**：第三方包内容**镜像进本仓库**（`QuartzWrt-ThirdParty` 仍是唯一"收集器"，
feed 仍只有 `quartz` / `thirdparty` 两条，锁定沿用 thirdparty 的 commit）；fork 仓库保留为
**上游跟踪 + `quartz` 适配分支**的改动脉络；同步走 `scripts/sync-forks.sh`（整仓镜像，排除 `.git`）。

| 上游 | 本组织 fork | 镜像路径 | 锁定（fork 侧） | 改动摘要 | 上次同步 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| [FUjr/QModem](https://github.com/FUjr/QModem) | [quartzwrt/QModem](https://github.com/quartzwrt/QModem) | `qmodem/` | `quartz` @ `9ffada22fd46168f1b82b9b36fe7a68b52dc98cb`（tag `v3.4.0_rc3-quartz1`） | `version.mk` 固定 `PKG_RELEASE`——feeds 对 `^SHA` 锁定走 `--depth 1` 浅克隆，上游基于 git commit-count 的自动 release 在该形态下恒为 1（实测 `git rev-list --count HEAD .` = 1）→ bump 后版本号不变、apk 无法升级；改为固定值，由发布流程手动 bump。**注**：`luci-app-qmodem-next` 上游自带硬编码 `PKG_RELEASE:=4`（非 git-count 派生、跨构建稳定），保持原样 | 2026-10-14（`9ffada2`；编译验证：qmodem + luci-app-qmodem-next + 依赖闭包 17 个 apk 产出 ✅） |
| [timsaya/openwrt-bandix](https://github.com/timsaya/openwrt-bandix) | [quartzwrt/openwrt-bandix](https://github.com/quartzwrt/openwrt-bandix) | `net/bandix/` | `main` @ `c95b03d40b30c31e89c090aaf134750f05bf3f19` | —（纯镜像；后续按需裁剪支持 arch / 二进制下载源） | 2026-10-14（`c95b03d`） |
| [timsaya/luci-app-bandix](https://github.com/timsaya/luci-app-bandix) | [quartzwrt/luci-app-bandix](https://github.com/quartzwrt/luci-app-bandix) | `net/luci-app-bandix/` | `main` @ `159a6de184b8cbd0694b40f018e737d0a3c82e7e` | —（纯镜像；Quartz 主题/i18n/App 联动适配落地时开 `quartz` 分支） | 2026-10-14（`159a6de`） |

**同步操作**：

```sh
scripts/sync-forks.sh                 # 全量同步（或指定 fork 名，如 qmodem）
git diff --stat                       # ① review
# ② 更新本表「上次同步」与锁定；③ 提交
```

**上游 → fork 镜像（main）与适配分支跟进**：

```sh
git remote add upstream <上游 URL>        # 仅首次
git fetch upstream && git checkout main && git merge --ff-only upstream/main && git push origin main
git checkout quartz && git rebase main    # 或 merge；随后单包编译 + 验收复验
# 发布：打 vX.Y.Z-quartzN tag → 更新本表 → 跑 sync-forks.sh → bump thirdparty 锁定
```

**发布前检查单**：① 逐 fork 同步上游；② `quartz` 分支 rebase 后单包编译；③ `scripts/sync-forks.sh` + review diff；
④ 更新本表；⑤ 提交 → 常规构建经 thirdparty 锁定自动携带（无需新增 feed 行）。
