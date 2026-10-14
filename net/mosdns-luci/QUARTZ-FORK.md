# QuartzWrt 受控 Fork 适配说明（quartz 分支）

基线：上游 tag `v5.3.4-r14`（`fae49a2`）。本分支承载 QuartzWrt 的适配改动
（TDD §4.7 受控 Fork 规范；台账 `QuartzWrt-ThirdParty/docs/FORKS.md`）。

## 适配动机

基座（ImmortalWrt 25.12）packages feed 已提供**原版 `mosdns` 5.3.3**；本仓库自带
**sbwml 补丁版 `mosdns` 5.3.4**（26 个 stats_api 等补丁）与应用强耦合
（应用生成的配置含补丁特性键 `log.size`、自带 init/uci/生成器）。
若只收应用、核心解析到基座原版，则不可用（详见 QuartzWrt WORKPLAN 坑位 #45）。

## 改名集（与基座同名包/文件避让，实现"两套 mosdns 并存零冲突"）

| 项 | 上游 | 本 fork（quartz 分支） |
| :--- | :--- | :--- |
| 核心**目录名** | `mosdns/` | **`mosdns-quartz/`**——`include/scan.awk` 按**目录名**（`$NF`）去重：feed 包目录与基座包目录同名时**整包被静默丢弃**（实测：仅改 PKG_NAME 时包在 `tmp/.packageinfo` 中消失、`feeds install` 静默跳过；目录同名即中招，与 PKG_NAME 无关） |
| 核心包名 | `mosdns` | **`mosdns-quartz`**（`PKG_SOURCE` 显式写 `mosdns-$(PKG_VERSION).tar.gz`） |
| 核心二进制 | `/usr/bin/mosdns` | **`/usr/bin/mosdns-quartz`**（install 规则 `GoPackage/Package/Install/Bin` 后 `mv`） |
| 服务 init | `/etc/init.d/mosdns` | **`/etc/init.d/mosdns-quartz`**（`PROG` 同步） |
| 应用依赖 | `+mosdns` | **`+mosdns-quartz`** |
| 引用点 | — | `hotplug/99-mosdns`、`ucitrack`（`init` 字段）、`acl.d`（两条 exec 白名单）、`basic.js`（restart exec）、`rpcd/ucode/luci.mosdns`（`mosdns version` → `mosdns-quartz version`） |

**保持不变**（与基座无冲突）：uci 文件 `/etc/config/mosdns`、配置目录 `/etc/mosdns/`、
生成配置 `/var/etc/mosdns.json`、`/usr/share/mosdns/`、rpcd 对象名 `luci.mosdns`。

## 同步纪律

上游发版后：`git fetch upstream && git checkout v5 && git merge --ff-only upstream/v5`
（`v5` 为上游默认分支名）→ `git checkout quartz && git rebase v5` → 单包编译 + VM 复验 → 打 `vX.Y.Z-quartzN` tag。
