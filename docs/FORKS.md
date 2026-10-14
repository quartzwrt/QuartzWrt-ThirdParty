# 受控 Fork 与镜像台账（TDD §4.7）

本文件登记 `thirdparty` 域内镜像内容的来源、同步状态与改动摘要。

**结构（2026-10-14 用户拍板）**：第三方包内容**镜像进本仓库**（`QuartzWrt-ThirdParty` 仍是唯一"收集器"，
feed 仍只有 `quartz` / `thirdparty` 两条，锁定沿用 thirdparty 的 commit）；受控 fork 仓库保留为
**上游跟踪 + `quartz` 适配分支**的改动脉络（无适配需求的走"上游直取"，不建 fork）；
同步走 `scripts/sync-mirrors.sh`（整仓镜像、排除 `.git`；可按条目排除不需要的包目录）。

| 来源 | 类型 | 镜像路径 | 锁定 | 改动/排除摘要 | 上次同步 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| [FUjr/QModem](https://github.com/FUjr/QModem)（fork：[quartzwrt/QModem](https://github.com/quartzwrt/QModem)） | 受控 Fork | `qmodem/` | fork `quartz` @ `9ffada22fd46168f1b82b9b36fe7a68b52dc98cb`（tag `v3.4.0_rc3-quartz1`） | `version.mk` 固定 `PKG_RELEASE`——feeds 对 `^SHA` 锁定走 `--depth 1` 浅克隆，上游基于 git commit-count 的自动 release 在该形态下恒为 1（实测 `git rev-list --count HEAD .` = 1）→ bump 后版本号不变、apk 无法升级；改为固定值，由发布流程手动 bump。**注**：`luci-app-qmodem-next` 上游自带硬编码 `PKG_RELEASE:=4`（非 git-count 派生、跨构建稳定），保持原样 | 2026-10-14（`9ffada2`；编译验证：qmodem + luci-app-qmodem-next + 依赖闭包 17 个 apk 产出 ✅） |
| [timsaya/openwrt-bandix](https://github.com/timsaya/openwrt-bandix)（fork：[quartzwrt/openwrt-bandix](https://github.com/quartzwrt/openwrt-bandix)） | 受控 Fork | `net/bandix/` | fork `main` @ `c95b03d40b30c31e89c090aaf134750f05bf3f19` | —（纯镜像；后续按需裁剪支持 arch / 二进制下载源） | 2026-10-14（`c95b03d`；编译验证：`bandix-0.12.11-r1.apk` ✅） |
| [timsaya/luci-app-bandix](https://github.com/timsaya/luci-app-bandix)（fork：[quartzwrt/luci-app-bandix](https://github.com/quartzwrt/luci-app-bandix)） | 受控 Fork | `net/luci-app-bandix/` | fork `main` @ `159a6de184b8cbd0694b40f018e737d0a3c82e7e` | —（纯镜像；Quartz 主题/i18n/App 联动适配落地时开 `quartz` 分支） | 2026-10-14（`159a6de`；编译验证：`luci-app-bandix-0.12.12-r1.apk` ✅） |
| [sbwml/luci-app-mosdns](https://github.com/sbwml/luci-app-mosdns) | 上游直取（无 fork） | `net/mosdns-luci/` | tag `v5.3.4-r14` @ `fae49a2` | **排除 `mosdns/`**——基座 packages feed 已提供 mosdns（5.3.3），收录同名包会被静默遮蔽（坑位 #11 同族）；只收 `luci-app-mosdns` + `geo2txt`。**踩坑记录**：rsync `--exclude` 必须用**锚定模式 `/mosdns`**——不加前导斜杠会连带排除 `view/mosdns/` 等同名子目录（首次镜像仅 18/42 文件、页面报 dispatcher `Internal node resolve error`，VM 验收抓回；已修正并全量复对 42/42）。**版本偏差登记**：应用依赖解析到基座 mosdns 5.3.3（上游仓库自带 5.3.4）——兼容性实测项 | 2026-10-14（`fae49a2`；编译验证：`luci-app-mosdns-1.7.14-r1` + `geo2txt-1.0.0-r1` + 基座 `mosdns-5.3.3-r1`〔依赖自动拉起〕+ i18n 中文包 ✅） |

**同步操作**：

```sh
scripts/sync-mirrors.sh                # 全量同步（或指定名称，如 mosdns-luci）
git diff --stat                        # ① review
# ② 更新本表「上次同步」与锁定；③ 提交
```

**上游 → fork 镜像（main）与适配分支跟进**（仅受控 Fork 条目）：

```sh
git remote add upstream <上游 URL>        # 仅首次
git fetch upstream && git checkout main && git merge --ff-only upstream/main && git push origin main
git checkout quartz && git rebase main    # 或 merge；随后单包编译 + 验收复验
# 发布：打 vX.Y.Z-quartzN tag → 更新本表 → 跑 sync-mirrors.sh → bump thirdparty 锁定
```

**发布前检查单**：① 逐来源同步上游（fork 先镜像 main、再 rebase 适配分支）；② 单包编译；
③ `scripts/sync-mirrors.sh` + review diff；④ 更新本表；⑤ 提交 → bump thirdparty 锁定（Builder `config/feeds.conf.extra`）。
