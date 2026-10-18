# 受控 Fork 与镜像台账（TDD §4.7）

本文件登记 `thirdparty` 域内镜像内容的来源、同步状态与改动摘要。

**结构（2026-10-14 用户拍板）**：第三方包内容**镜像进本仓库**（`QuartzWrt-ThirdParty` 仍是唯一"收集器"，
feed 仍只有 `quartz` / `thirdparty` 两条，锁定沿用 thirdparty 的 commit）；受控 fork 仓库保留为
**上游跟踪 + `quartz` 适配分支**的改动脉络（无适配需求的走"上游直取"，不建 fork）；
同步走 `scripts/sync-mirrors.sh`（整仓镜像、排除 `.git`；可按条目排除不需要的包目录）。

| 来源 | 类型 | 镜像路径 | 锁定 | 改动/排除摘要 | 上次同步 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| [FUjr/QModem](https://github.com/FUjr/QModem)（fork：[quartzwrt/QModem](https://github.com/quartzwrt/QModem)） | 受控 Fork | `qmodem/` | fork `quartz`（**待推送补丁**：`v3.4.0_rc3-quartz2`；镜像内已落，见下行"适配点 ②"） | `version.mk` 固定 `PKG_RELEASE`——feeds 对 `^SHA` 锁定走 `--depth 1` 浅克隆，上游基于 git commit-count 的自动 release 在该形态下恒为 1（实测 `git rev-list --count HEAD .` = 1）→ bump 后版本号不变、apk 无法升级；改为固定值，由发布流程手动 bump。**注**：`luci-app-qmodem-next` 上游自带硬编码 `PKG_RELEASE:=4`（非 git-count 派生、跨构建稳定），保持原样。**适配点 ②（2026-10-18，蜂窝轮）**：`get_at_cfg` 增**可选 `lang` 参数**（`zh`\|`en`）——App 按自身界面语言请求预置命令标签语言，避免"中文 App + 英文路由器 LuCI"时拿到英文命令名；缺省行为不变（仍取 `luci.main.lang`），对网页端透明。**⚠️ 待办**：fork `quartz` 分支需落同款补丁并打 tag `v3.4.0_rc3-quartz2`——**当前改动只在镜像**（`qmodem/`），未推送前**再次运行 `scripts/sync-mirrors.sh qmodem` 会覆盖它** | 2026-10-14（`9ffada2`，`quartz1`；编译验证：qmodem + luci-app-qmodem-next + 依赖闭包 17 个 apk 产出 ✅）；2026-10-18（镜像内 `quartz2` 适配待回推 fork） |
| [timsaya/openwrt-bandix](https://github.com/timsaya/openwrt-bandix)（fork：[quartzwrt/openwrt-bandix](https://github.com/quartzwrt/openwrt-bandix)） | 受控 Fork | `net/bandix/` | fork `main` @ `c95b03d40b30c31e89c090aaf134750f05bf3f19` | —（纯镜像；后续按需裁剪支持 arch / 二进制下载源） | 2026-10-14（`c95b03d`；编译验证：`bandix-0.12.11-r1.apk` ✅） |
| [timsaya/luci-app-bandix](https://github.com/timsaya/luci-app-bandix)（fork：[quartzwrt/luci-app-bandix](https://github.com/quartzwrt/luci-app-bandix)） | 受控 Fork | `net/luci-app-bandix/` | fork `main` @ `159a6de184b8cbd0694b40f018e737d0a3c82e7e` | —（纯镜像；Quartz 主题/i18n/App 联动适配落地时开 `quartz` 分支） | 2026-10-14（`159a6de`；编译验证：`luci-app-bandix-0.12.12-r1.apk` ✅） |
| [sbwml/luci-app-mosdns](https://github.com/sbwml/luci-app-mosdns)（fork：[quartzwrt/luci-app-mosdns](https://github.com/quartzwrt/luci-app-mosdns)） | 受控 Fork（**整套收录**：应用 + 核心 + geo2txt） | `net/mosdns-luci/` | fork `quartz` @ `93fd87dafa7302e2ddf4c8576b932e257feca208`（tag `v5.3.4-r14-quartz4`；基线上游 `fae49a2`） | **整套改名适配（与基座原版 mosdns 并存零冲突；坑位 #45）**：核心包 `mosdns`→**`mosdns-quartz`**（`PKG_SOURCE` 显式 `mosdns-$(PKG_VERSION).tar.gz`）、二进制 `/usr/bin/mosdns`→`mosdns-quartz`、init `/etc/init.d/mosdns`→`mosdns-quartz`、应用依赖 `+mosdns`→`+mosdns-quartz`；引用点 6 处同步（hotplug/ucitrack/acl.d×2/basic.js/rpcd ucode `mosdns version`）；uci 文件、`/etc/mosdns/`、`/var/etc/mosdns.json`、rpcd 对象名保持不变。详见 fork 内 `QUARTZ-FORK.md` | 2026-10-14（`quartz4`；**VM 验收 ✅**：`apk add luci-app-mosdns` 自动解析整套、服务 `mosdns-quartz 5.3.4-r14` 运行、5335 端口 DNS 查询实测解析、页面〔basic/statistics/update〕渲染、探针 `services.mosdns.running=true`） |
| [JiaY-shi/fancontrol](https://github.com/JiaY-shi/fancontrol) | 上游直取 | `utils/fancontrol/` | tag `v2.1.0` @ `bdd72939b50a483333a6928f37bddce31259c002` | —（纯镜像；**一仓两包**：`fancontrol/` 守护进程〔hwmon PWM 连续调速，`auto` 自动发现 CPU/SoC 热区与 `pwmfan` hwmon，规避 hwmon 序号漂移〕+ `luci-app-fancontrol/` 配置页）。**来源说明**：vendor FNet3399 成品镜像内同名两包出自同作者旧版线（`fancontrol` 1-r3 / `luci-app-fancontrol` 1.0-r1，维护者 JiaY-shi；LuCI 侧 menu/acl 与 rockjake 分支逐字节同源），本条目取作者 2.x 演进版；设备侧调速曲线走 Builder `devices/erya_fnet-3399/` 的 uci-defaults，**不改包本身**（无适配需求故不建 fork） | 2026-10-16（`bdd7293`，tag `v2.1.0`；编译验证见 Builder `devices/erya_fnet-3399/README.md`） |

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
