# WP-7 设计文档：ThirdParty 扩包 + 运行时资源清单

**版本**: v0.1（讨论稿）
**日期**: 2026-10-14
**状态**: 待拍板（§8 共 11 项 D1–D11；**D11 已确认并落地**——TDD 受控 Fork 规范；**D6 已拍板**——收录 qmodem〔受控 Fork〕）
**依据**: TDD §3.1（双 Feed/不可变上游）、§4.1–4.4（版本锁定/运行时资源）、§5（模式 A/B）、§6（准入清单）；WORKPLAN §3 WP-7
**基线**: 锁定基座 ImmortalWrt 25.12 @ `ce35a9e4`；本 feed 锁定 `30846b9`（`utils/luci-lib-docker` 唯一收录）

---

## 1. 目标与边界

**目标**（WORKPLAN §3 WP-7）：
1. 把常用第三方插件按「薄 Makefile + 版本锁定」引入 `thirdparty` feed；
2. 建立**运行时资源清单**（TDD §4.4：核心二进制、GeoIP/规则库的下载项及校验和）。

**边界（不做）**：
- 不改上游源码（不可变上游）；不依赖 feeds 顺序兜底同名包；
- 不开发 Bridge 适配层（归 WP-8）；不改 daemon/app-api 代码（归 WP-4/WP-5，本 WP 只**投放数据文件**）；
- 签名/OTA（归 WP-9）。

---

## 2. 遮蔽筛查：基座已提供什么（WP-7 步骤 1 结果）

2026-10-14 对锁定基座（`build/immortalwrt/feeds/`）逐目录实测：

| 候选 | 基座状态 | 结论 |
| :--- | :--- | :--- |
| PassWall | **luci feed 自带 `luci-app-passwall` 完整版**（luasrc/htdocs/root/po + 核心选择菜单）；核心依赖（xray-core、sing-box、hysteria、chinadns-ng、dns2socks、naiveproxy、v2ray-plugin、geoview、ipt2socks、microsocks、haproxy、shadowsocks-rust、tcping、lyaml 等）在 packages feed | **不收录**（直接 DEPENDS） |
| luci-app-ttyd / ttyd | luci feed 有 `luci-app-ttyd`，packages feed 有 `ttyd` | **不收录** |
| openclash / dockerman / luci-lib-docker | 既有结论（2026-10-12）：前两者不收录，`luci-lib-docker` 已收录 | 维持 |
| 其他基座已提供（抽样） | homeproxy、dae/daed、v2raya、nlbwmon、adguardhome、smartdns、openlist/alist、frpc/frps、ddns-go、zerotier、tailscale-community、netdata、msd_lite、modemband、sms-tool-js、filebrowser(-go)、rustdesk-server、wechatpush、watchcat、sqm、syncthing、transmission、qbittorrent、aria2、mosdns 核心（**无 LuCI**） | 一律不收录 |
| **基座缺失候选** | **bandix**（`timsaya/luci-app-bandix` + `openwrt-bandix`）、**qmodem**（`FUjr/QModem`）、**luci-app-mosdns**（核心在基座、LuCI 应用缺） | 进入 §3 评估 |

> 结论：WORKPLAN 原候选清单（PassWall、luci-app-ttyd）**已被基座覆盖**；实际扩包对象收敛为下表三个。

---

## 3. 候选逐包评估（TDD §6 准入清单）

### 3.1 bandix（推荐收录，首个新包）

**组成（三仓库，同一作者 timsaya）**：

| 仓库 | 角色 | 许可 | 活跃度 | 锁定点 |
| :--- | :--- | :--- | :--- | :--- |
| `timsaya/bandix` | 核心（Rust + eBPF） | Apache-2.0 | 2026-09-28 推送 | Release tag `v0.12.11`（提供 x86_64/aarch64/arm/mips/riscv64 等 musl 预编译资产） |
| `timsaya/openwrt-bandix` | 打包层（Makefile + init/config/keep） | Apache-2.0 | 2026-09-28 推送 | tag `v0.12.11` |
| `timsaya/luci-app-bandix` | LuCI 前端（JS + rpcd 薄壳 + menu/acl/po） | Apache-2.0 | 2026-09-28 推送（989★） | tag `v0.12.12` |

**架构模式**：**模式 A 近亲**——核心 `bandix` 常驻（procd），暴露本地 HTTP API（`127.0.0.1:8686`，uci `bandix.general.port`）；LuCI 经 rpcd 脚本 `luci.bandix` 转译（devices/limits/metrics/connection/dns/quotas 等端点）。App/Dashboard 可经 rpcd 或 daemon 消费，与 Quartz「设备表 / 流量 / 限速」场景吻合。

**引入方式**（D3；**2026-10-14 用户方向修订：Fork 引入**；同日再修订 **fork 范围**——见下）：
- **fork 范围（用户澄清）**：只 fork **`openwrt-bandix`（打包层）+ `luci-app-bandix`（LuCI 前端）**两个仓库；**核心 `timsaya/bandix` 不 fork、不引入**——它是面向通用 Linux 的 Rust 工具（非 OpenWrt 包），本固件只消费其 **release 预编译二进制**（`openwrt-bandix` 的 Makefile 即从此下载，逐 arch SHA256 固定）；
- **结构实测（决定 feed 形态）**：两个 fork 仓库均为"包根形态"（`openwrt-bandix/Makefile`、`luci-app-bandix/Makefile` 位于根下第 1 层）——`scripts/feeds` 扫描深度 5 内有效（`update_index` → `SCAN_DEPTH=5`），**因此可直接作为独立 feed 行**（§3.5 形态 ②），零复制且上游 Makefile（含 LuCI 的 `LUCI_*` 定义与安装规则）原样可用；备选形态 ①（thirdparty 薄 Makefile 指 fork）需我们复刻上游安装规则、会漂移，不推荐用于本对包；
- **fork 内容与改动面**：`openwrt-bandix` fork——按需裁剪 arch（v1 收 x86_64/aarch64）、后续可把二进制下载源改为我们可控镜像；`luci-app-bandix` fork——承载 Quartz 适配（主题对齐/i18n/App 联动/probes 投放）；
- **锁定**：feed 行锁 `^<commit>`；适配发布打 `vX.Y.Z-quartzN` tag（§3.5 纪律）；
- 升级流程 = merge 上游 → rebase 适配分支 → 打 tag → bump 锁定 + 回填 hash → 单包编译 → 全量构建 → VM 复验。

**TDD §6 清单核对**：
- 上游活跃度 ✓（2026-09 仍在发版）；版本锁定 ✓（tag + 逐 arch SHA256）；
- 依赖冲突：`zoneinfo-all`、`conntrack`、`iw`（基座 packages feed / base tree 均可得）✓；LuCI 侧 `+luci-base +luci-lib-jsonc +curl` ✓；
- 内核/硬件前提：**eBPF 类插件须核实目标内核与 BTF 支持**（x86_64 与 RK3399/aarch64 双目标，**列为验收项**）；
- 许可证 Apache-2.0 ✓；供应链审计：**预编译二进制**（来源 = 上游 `timsaya/bandix` release，SHA256 固定；无源码可复现构建——登记接受，D3 一并拍板）；
- 集成注意：上游 README 要求关闭**硬件流量卸载 / Turbo ACC**；基座默认 `firewall.config` 为 `flow_offloading 1`（软件卸载）+ `fullcone 1`，硬件卸载默认未开——软件卸载对 eBPF 统计的实际影响**须 VM 实测**（D4）。

**预装与否**（D5）：bandix 是「设备流量/限速」的 App 联动点，倾向加入 `quartz-defaults` 预装（体积待实测，VM 验收时记录）。

### 3.2 qmodem（5G 模组管理）——✅ 用户拍板收录（受控 Fork，2026-10-14）

**上游**：`FUjr/QModem`，436★，活跃（2026-10-10 推送），版本 `3.4.0_rc3`。

**决策（D6 ✅）**：用户拍板「还是收录 qmodem，用受控 fork 的方式」→ **收录方式 = 受控 Fork + feed 形态 ②**（`quartzwrt/QModem` fork → `feeds.conf.extra` 追加 `src-git qmodem https://github.com/quartzwrt/QModem.git^<我们的 commit>`）。**可行性已实测（见下）**。

**可行性核查（2026-10-14，浅克隆 + 基座逐项对照）**：
- **上游天生 feed 形态**：README 即 `src-git qmodem …` 安装法；仓库根即 `application/` + `luci/` + `driver/` 多包结构（`scripts/feeds` 扫描深度 5 内有效）；**无 submodule**；浅克隆 16 MB；
- **包集**：`application/` 17 包（qmodem / qmodem-settings / ubus-at-daemon / tom_modem / modem_scan / libqmodem-sms / qmodem-seal / qmodem-smsd / qmodem-sipd / qmodem_monitor / sms-tool_q / sms-forwarder(-next) / quectel-CM-5G-M / qfirehose / ndisc6 / qmodem-voip）+ `luci/` 9 应用（推荐 `luci-app-qmodem-next`，`+qmodem +qmodem-smsd +sms-forwarder-next`）+ `driver/` 7 个 kmod（qmi_wwan_q/_f/_s、pcie_mhi、nss 三件套）；
- **上游 CI 同族验证**：`.github/workflows/{x64,arm64}_apk.env` 在 **OpenWrt snapshot apk 体系**下对 **x86/64 与 aarch64（mvebu/cortexa53）** 编译 → 与我们基座（25.12 / apk / kernel 6.12）同族且覆盖两个目标架构；
- **依赖闭包核对（基座侧全部可得）**：jq、bc、usbutils、pciutils、umbim（base tree）、terminfo（ncurses 子包）、xxd（vim 子包）、`kmod-usb-*` 系列（base tree）；其余依赖（ubus-at-daemon/qmodem-settings/tom_modem/sms-tool_q/modem_scan/qmodem-seal/…）全在 fork 内；`luci-app-qmodem-*` 额外依赖 `luci-app-mwan3`、`libubus-lua`（基座 luci feed 有）；
- **feed 可提供 KernelPackage**：`include/scan.mk` GREP_STRING 含 `KernelPackage`，基座 packages feed `kernel/` 目录即先例 → fork 的 `driver/` 可作为 kmod 包；**nss 三件套 Kconfig 限定 `TARGET_qualcommax_*`** → 我们的目标不会被选中（无风险）。

**三个必须处理点（已实测确认）**：
1. **`PKG_RELEASE` 在 feed 形态下失效 → fork 必须固定**：`version.mk` 用 git commit count 生成 release，而 `scripts/feeds` 对 `^SHA` 锁定用 **`--depth 1` 浅克隆**（实测：`git rev-list --count HEAD .` = **1**、bump 匹配为空）→ release 恒为 1，**bump 锁定后版本号不变、apk 装不上升级** → 在 fork `quartz` 分支改为**固定 `QMODEM_RELEASE`（每次发布手动 bump）**；
2. **驱动选择**：`qmodem` 的 Kconfig **默认 vendor QMI 驱动**（`kmod-qmi_wwan_q/_f/_s` 随包拉起），但**上游自己的 CI 用的是 generic 驱动**（`openwrt_package.config`：`qmodem_INCLUDE_generic-qmi-wwan=y`）→ 我们 v1 同样用 generic（seed 配置项，不动 fork），vendor 驱动留设备专项实测；**另注意**基座 packages feed 已有 `kmod-usb-net-qmi-wwan-quectel/-fibocom`（与 fork 的 `kmod-qmi_wwan_q/_f` 包名不同、可能产出同名 `.ko`）→ 两者不可同装（依赖冲突核查项）；
3. **许可证约束（须接受）**：MPL-2.0 **+ 禁止商用附加条款**（非 OSI 许可）——收录即接受「不得商用」约束；随包携带 LICENSE、`FORKS.md` 登记、README 标注；**若 QuartzWrt 将来商业化，必须下架本包**。

**落地边界（跨 WP 登记）**：① 设备侧预装（FNet3399）归 WP-11 的 `devices/` 层（DEVICE_PACKAGES + manifest 断言）；② 不预装则需要 D10 软件源自建才能按需安装（强联动）；③ App/probes 联动面已存在（fork 内带 procd init + rpcd ACL），登记为 seam（probes.d 描述符可随 fork 投放，后置）。

### 3.3 luci-app-mosdns（DNS；补充候选，P2）

- 基座已有 **mosdns 5.3.3 核心**（packages feed），**无 LuCI 应用**；
- 上游 `sbwml/luci-app-mosdns`（GPL-3.0，1853★，活跃 2026-09-13，v1.7.14）含三目录：`luci-app-mosdns` / `mosdns` / `geo2txt`；LuCI 依赖 `+mosdns +uclient-fetch +v2ray-geoip +v2ray-geosite +geo2txt +ucode`（`v2ray-geodata` 在基座提供 geoip/geosite；**`geo2txt` 基座没有**，需一并收录）。
- 同名包处置：基座已有 `mosdns` → 按规则**只收 LuCI 应用 + geo2txt**，核心依赖解析到基座 5.3.3（版本兼容性须实测）。
- **倾向**：P2 候选池——Quartz 的 DNS 场景已有 smartdns/adguardhome 在基座，mosdns LuCI 属增强项，可作第二个收录对象或后置（D7）。

### 3.4 明确不收录（防回访）

- **mihomo/nikki、ssr-plus**：基座已有 openclash / passwall / homeproxy / dae / daed 五套代理，功能冗余、维护面大；
- **istore 商店**：与 apk/双 Feed 模型冲突（自带 feed + 二进制分发）；
- 其余基座已提供者见 §2 表。

### 3.5 Fork 引入模型（用户方向，2026-10-14）

**动机**：上游结构不适配薄 Makefile（打包仓库型 / 预编译二进制型 / 多包 feed 型），或需要 QuartzWrt 适配改动（主题对齐 / i18n / App 联动 / 探针投放）时，"复制上游文件进本仓库"会漂移且不可 diff——改为 **fork 承载改动**。

**模型（纪律）**：
- **fork 范围最小化**：只 fork **OpenWrt 集成所需的仓库**（打包层、LuCI 前端）与**需要适配改动的部分**；上游面向通用 Linux / 其他平台的源码仓库**不 fork、不引入**，只按需消费其发布物（二进制/规则库，SHA256 固定）；
- **fork 到 `quartzwrt` 组织**，仓库名与上游同名（便于对照与 GitHub fork 网络关系）；
- **分支纪律**：`main` 保持上游镜像（只做 fast-forward/merge，不放自有提交）；适配改动走 `quartz` 分支，发布打 `vX.Y.Z-quartzN` tag；**feed 锁定我们的 tag/commit**（不用裸分支）；
- **同步纪律**：上游发版 / 发布前 → merge 上游 → rebase 适配分支 → 重跑单包编译 + VM 复验；有价值的改动尽量 PR 回上游（减少长期分叉）；
- **登记**：fork 清单与同步状态登记 `docs/FORKS.md`（待建；含 上游→fork 对应、锁定 tag、改动摘要、上次同步日期）；
- **与 TDD §3.1 的关系**：现条款「禁止 Fork 上游改源码（确需 Fork 属特例，须评审）」需修订为**受控 Fork 规范**（即本节纪律）——属 TDD 变更，**需用户拍板（D11）**；
- **与 WP-10 模式的分工**：WP-10（luci-app-tailscale）＝「上游停更 → 再开发」进 `quartz` feed；本模型面向**活跃上游的适配**，包仍登记在 thirdparty（源指 fork）。若某包分叉深到"再开发"程度（上游停更/大改）→ 按 WP-10 模式迁 `quartz` feed；
- **feed 形态两选**（D11 子项）：① **thirdparty 内薄 Makefile 指向 fork**（默认；保持双 Feed 叙事）；② fork 仓库本身是 feed 形态（如 qmodem：根目录即多包目录）时，可**作为独立 feed 行**追加进 `feeds.conf.extra`（锁 commit）——零复制、保留其 git 版本逻辑，但"双 Feed"叙事与 CI 检查需同步更新。

---

## 4. 运行时资源清单（TDD §4.4）——本 WP 核心交付

### 4.1 现状与缺口

- **已有**：openclash 核心版本读取由 daemon **内置探针**完成（`quartz-daemon/files/probes.d/openclash.json` → 快照 `services.openclash.core`，WP-4 §13.1 机制）；`services` 开放映射即 TDD §4.4 点名的物化通道（WP-4 DESIGN §12.2 已声明「无需新机制」）；
- **缺口**：①「清单」文档/机读文件不存在（README 已注「清单文件待建」）；②passwall 等其余运行时下载插件无版本探针；③镜像源策略未定。

**覆盖对象（v1，实测其运行时下载行为）**：

| 插件 | 运行时下载项 | 默认来源（实测） |
| :--- | :--- | :--- |
| openclash（预装） | 核心二进制（clash meta/tun 等）、GeoIP.dat/GeoSite.dat、Country.mmdb、GeoLite2-ASN.mmdb | `openclash_geo.sh`：Loyalsoldier / xishang0128 / alecthw 的 GitHub releases + `github_address_mod` 加速前缀 + 自定义 URL |
| passwall（基座提供） | gfwlist / chnroute / chnroute6 / chnlist / geoip / geosite | `rule_update.lua`：jsDelivr / ispip.clang.cn / GitHub（全部可自定义 URL） |
| bandix（本 WP 收录） | 无（二进制随包） | — |

### 4.2 清单形态（D1）

- 载体：`docs/RUNTIME-RESOURCES.md`（人读、权威声明）+ `docs/runtime-resources.json`（机读，同源数据，供后续 daemon/Bridge/CI 消费）；
- 条目 schema（草案）：

```json
{
  "id": "openclash",
  "title": "OpenClash",
  "resources": [
    { "kind": "core", "name": "clash-meta",
      "url": "<上游 release 或自定义>", "version_source": "exec:/etc/openclash/clash -v",
      "sha256": "runtime-rolling | <固定值>", "mirror": "github_address_mod", "verify": "下载后校验/日志" },
    { "kind": "geo", "name": "GeoIP.dat",
      "url": "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat",
      "version_source": "file mtime", "sha256": "rolling" }
  ],
  "exposure": { "services_key": "openclash", "fields": { "core": "版本" } },
  "update_channel": "插件内置更新（OpenClash 自身）"
}
```

- **能力边界（如实声明）**：`releases/latest` 滚动资源**无法预固定 SHA256**——清单标注 `rolling`，治理手段 = 镜像源 + 下载后校验 + 日志；可固定 URL 的资源（如 bandix 预编译包）写死 SHA256。

### 4.3 与 daemon/App 的衔接（零代码改动路径）

- **版本读取**：复用 probes.d（WP-4 §13.1）——为清单覆盖插件投放 `probes.d/<id>.json`（openclash 已有；新增 passwall 等），`services.<id>.<field>` 自动进快照 → Dashboard（WP-3 服务卡泛化）/App（WP-6 应用页）可见；
- **投放归属**（D2）：
  - 通则：thirdparty 收录的新包**随薄 Makefile 投放探针描述文件**（WP-4 DESIGN §11 已登记约定）；
  - 基座已有包（openclash/passwall）无我方包承载 → 倾向**新设 `quartz-runtime-resources` 小包**（thirdparty，承载「清单文件 + 探针描述符 + 镜像默认值」三件套），所有权清晰、不触 WP-4/共享文件（备选：quartz-defaults 追加式投放，跨 WP 登记）；
- **更新状态比较**（「有新版本」）：需联网查询上游 release——v1 后置（TDD §4.4 已声明「随本清单治理落地」，触发动作归 WP-5/Bridge）。

### 4.4 镜像源策略（D8）

- v1（推荐，**不新建镜像基础设施**）：①清单登记「官方源 + 推荐加速前缀」；②由 `quartz-runtime-resources`（或 quartz-defaults）投放 uci-defaults，把 openclash/passwall 下载地址预置为可控镜像优先；③文档声明校验与回退路径；
- 后置：自建镜像（对象存储/CI 同步 + 校验和索引）——需基建，归 Builder/WP-9 或新 WP。

### 4.5 软件源（apk feed 发布）——分层评估（2026-10-14 实测，用户提出「要不要自建软件源」）

**两层「镜像」区分**：§4.4 管**运行时资源**（插件运行中下载的核心/规则库）；本节管 **apk 软件源**（feeds 发布的包仓库）。技术上独立，但**可共用同一托管基建**。

**现状实测**：
- 固件 `distfeeds.list` 共 9 条，全部经 `CONFIG_VERSION_REPO`（默认 `https://downloads.immortalwrt.org/releases/25.12-SNAPSHOT`）由 `FeedSourcesAppendAPK` + `VERSION_SED_SCRIPT`（`%U` 替换）生成 → **改 `CONFIG_VERSION_REPO` 一处即可把全部源重定向到自建仓库**（也可用现成的 `customfeeds.list` 追加）；
- 逐条探测官方源：base/luci/packages/routing/telephony = 200；**quartz/thirdparty = 404（我们从未发布）**；**video = 404（官方也未发）** → 坑位 #41（`apk upgrade` 整体拒绝）的直接成因；
- **漂移实测（关键）**：官方快照仓库 **旧于** 本锁定基座——kernel `6.12.103` vs `6.12.112`、base-files `1949~1d34e7b8` vs `1954~ce35a9e4`、rpcd `2026.07.19` vs `2026.10.04` → ①基座侧 `apk upgrade` 无物可升（我们更新）；②**kmod 类包依赖精确内核版本，无法安装**；③部分用户态新包依赖解析失败；
- 体积实测：官方 x86_64 全量 ≈ **3.45 GB**（packages 3.0G / base 326M / telephony 46M / target 34M / luci 23.5M / routing 3M）；自有 feed 增量极小（当前 quartz 6.1 MB + thirdparty 20 KB/构建）；
- 签名现状：`CONFIG_SIGNED_PACKAGES=y`；构建树自动生成 `private/public-key.pem`（**每个全新构建树一把新钥匙**，固件仅信任自己的 `public-key.pem`）→ **自建源必须配稳定密钥（归 WP-9）**，否则跨版本固件验签失败。

**结论与建议路线（D10）**：
- **必须做，非可选**：quartz/thirdparty 是产品价值本体（主题/Dashboard/tailscale 适配版/bandix…），不发布 → 坑位 #41 永久存在、**App 软件包管理面（WP-5 W5.7 + WP-6 W6.8 已实现）空转**、按需安装（不预装策略）不可用；
- **阶段 1（小成本，可即做）**：发布**自有 feed**（quartz+thirdparty，可选 target 包）到自建源；`CONFIG_FEED_quartz/thirdparty/video=m`（`scripts/feeds` 的 tristate 机制：M = 该行注释掉）+ 源地址经 `CONFIG_VERSION_REPO`（全量替换）或 `customfeeds.list`（追加）接入；基座 feed 暂留官方（已知限制：kmod 不可装、基座侧无升级）；
- **阶段 2（并入 WP-9）**：稳定签名密钥（私钥→CI Secrets、公钥预置）+ **全量发布**（含基座全量包）→ 完全自包含、可复现升级，ASU/OTA 的前提；
- **托管**：全量 ≈3.45 GB/target（x86_64）+ aarch64（FNet3399）另计 → **Cloudflare R2**（10 GB 免费、零出口费、S3 API 便于 CI 增量同步）优于 GitHub Pages（1 GB 仓库/100 GB 月流量软限，仅够阶段 1）；同一托管可顺带承载 §4.4 运行时资源镜像。

---

## 5. feed 结构与工程规范（本 WP 落地）

- **目录**：沿用 TDD §3.1 的 `net/` / `utils/` / `libs/` 归类；LuCI 前端与其后端同目录（如 `net/bandix` + `net/luci-app-bandix`）；
- **薄 Makefile 两型模板**（入 `docs/`）：
  - ①git 源码型：`PKG_SOURCE_PROTO:=git` + `PKG_SOURCE_VERSION:=<tag>` + `PKG_MIRROR_HASH`（现有 luci-lib-docker 范式）；**需要适配改动时 URL 指向 `quartzwrt` fork（§3.5），锁 `-quartzN` tag**；
  - ②预编译二进制型：per-arch `PKG_SOURCE`/`PKG_HASH`（release URL 固定；bandix 范式——v1 指上游 release，可选迁 fork release）；
- **升级流程**：TDD §4.3 半自动（maintainer-tools/update_git_source_package.sh）+ ①型（fork）需 merge 上游/rebase 适配分支（§3.5 同步纪律）+ ②型需更新逐 arch hash；单包编译 → 全量构建 → VM 复验；
- **CI 缺口（D9）**：现有 `check-duplicate-packages.sh` **只查 quartz-vs-thirdparty，不查基座 feed**——而基座遮蔽是「先列者胜」且基座在前，收录基座已有的包会被**静默遮蔽**（坑位 #11 同族）。建议扩展扫描基座 feeds（跨 WP 登记 WP-1）；预装新包时同步在 `check-manifest.sh` 公共断言追加（跨 WP 登记）。**形态 ② 落地后**：`config/feeds.conf.extra` 新增 fork feed 行（锁 commit），同名包检查与「锁定 feed 强制重克隆」逻辑需覆盖全部自建 feed（本地 `build-local.sh` + CI，跨 WP 登记 WP-1）；
- **README 更新**：收录表 + 引入流程 + 清单指针。

---

## 6. 验收标准（本 WP 完成定义）

1. 收录包**单包编译通过**；全量构建进镜像——预装则 manifest 在列（`check-manifest.sh` 断言），不预装则 `bin/packages/<arch>/thirdparty/` 产出 apk 且镜像内 `apk add` 实测安装成功；
2. **VM 验收（bandix）**：procd 服务运行、LuCI 页真数据（流量/设备表）、rpcd `luci.bandix` 可调、快照出现 `services.bandix`；流量统计与对照（nlbwmon/ifstat）抽样一致；eBPF/BTF 在 x86_64 与 aarch64（RK3399）双目标核实；flow offloading 交互实测（D4 依据）；
3. **运行时资源清单成文**（MD + JSON）+ openclash/passwall 版本探针 VM 实测可见（`services.openclash.core` / `services.passwall.core`）；
4. **qmodem（W7.8）**：依赖闭包单包编译通过（qmodem + `luci-app-qmodem-next` + generic QMI 驱动）；全量构建进镜像（`bin/packages/<arch>/qmodem/` 产出 apk）；VM 内 `apk add` 安装成功、LuCI 页面在 quartz 主题下逐页渲染正常、procd 服务启动；`PKG_RELEASE` 固定后 **bump 锁定 commit → 版本号递增 → apk 可升级**（同版本不可升级的反例回归）；
5. 文档同步：TDD 相关段落（§4.4 如涉及）/ README / WORKPLAN 回写。

---

## 7. 实施分解（W7.x，拍板后执行）

| 步骤 | 内容 | 依赖 |
| :--- | :--- | :--- |
| W7.1 | 设计定案（本文档 → v1.0，D1–D11 拍板） | — |
| W7.2 | bandix 收录：**建两个 fork**（`quartzwrt/openwrt-bandix` + `quartzwrt/luci-app-bandix`，§3.5 分支纪律）+ `feeds.conf.extra` 增 feed 行（锁 commit）+ hash 回填 + 单包编译 + probes.d 投放 | D3/D4/D5/D11 |
| W7.3 | 运行时资源清单 v1（MD + JSON + 镜像默认值〔如拍板〕） | D1/D8 |
| W7.4 | openclash/passwall 版本探针投放（按 D2 归属落地） | D2 |
| W7.5 | 全量构建 + VM 验收（§6 全项） | W7.2–W7.4 |
| W7.6 | 文档同步（README / TDD 两副本如涉及 / WORKPLAN） | W7.5 |
| （可选）W7.7 | mosdns LuCI 收录（P2，按 D7） | D7 |
| W7.8 | **qmodem 收录**（受控 Fork）：建 `quartzwrt/QModem` fork → fork 固定 `PKG_RELEASE`（quartz 分支）→ `feeds.conf.extra` 增 feed 行（锁 commit）→ 依赖闭包单包编译（qmodem + luci-app-qmodem-next + generic 驱动）→ 全量构建 → VM 安装/渲染验收（quartz 主题逐页） | D6 ✅/D10 |

---

## 8. 待拍板项

| # | 事项 | 推荐案 |
| :--- | :--- | :--- |
| D1 | 运行时资源清单载体与 schema | MD（人读）+ JSON（机读）双轨，§4.2 草案 schema |
| D2 | 探针描述符/清单/镜像默认值的投放归属 | 新设 `quartz-runtime-resources` 小包（thirdparty）承载三件套；新收录包随包投放 |
| D3 | bandix 引入方式与预编译二进制信任链 | **Fork 引入（§3.5，用户 2026-10-14 确认）**：fork 范围＝**仅 `openwrt-bandix` + `luci-app-bandix`**（核心 `timsaya/bandix` 不 fork——通用 Linux 工具，只消费其 release 二进制 + SHA256）；两 fork 均为包根形态 → **feed 形态 ②（独立 feed 行，锁 commit）**；适配（主题/i18n/App 联动）在 fork 的 `quartz` 分支承载 |
| D4 | bandix × flow offloading 默认配置策略 | VM 实测后定：若软件卸载影响统计 → 预置关卸载（或文档指引），不默认牺牲转发性能 |
| D5 | bandix 预装与否（quartz-defaults 追加） | 预装（App 联动点；体积实测后确认） |
| D6 | qmodem 收录（许可证风险 + 引入方式） | ✅ **用户拍板（2026-10-14「还是收录 qmodem 吧，用受控 fork」）**：收录 = 受控 Fork + feed 形态 ②（`quartzwrt/QModem` → `feeds.conf.extra` 锁 commit 行）；**接受** MPL-2.0+禁商用约束（商用化即下架）；fork 固定 `PKG_RELEASE`；v1 用 generic QMI 驱动（vendor 驱动留设备专项）；设备预装归 WP-11 |
| D7 | luci-app-mosdns（+geo2txt）收录 | P2 候选池，可后置 |
| D8 | 镜像源策略 | v1 文档化 + 默认值投放；自建镜像后置 |
| D9 | CI 同名包检查扩到基座 feed + 预装包 manifest 断言登记 | 扩展扫描（跨 WP 登记 WP-1） |
| D10 | **软件源自建（apk feed 发布）路线与托管**（§4.5，用户提出） | 分阶段：阶段 1 发布自有 feed（闭环 #41 + 激活 App 软件包面，`CONFIG_FEED_*=m` 注释死链 + `CONFIG_VERSION_REPO`/`customfeeds.list` 接入）→ 阶段 2 全量发布（WP-9 合流，稳定签名密钥）；托管 Cloudflare R2（与 §4.4 运行时资源镜像共用基建） |
| D11 | **Fork 引入升级为 thirdparty 通用策略**（§3.5，用户方向；含 TDD §3.1「不可变上游」条款修订 + fork 分支/同步纪律 + `docs/FORKS.md` 登记 + feed 形态两选） | ✅ **用户已确认（2026-10-14「大致是对的，要改」）→ TDD 已修订**：§3.1 三大原则 #3 + 引入方式约定改写、新增 **§4.7 受控 Fork 规范**、术语表增「受控 Fork」、§6 清单增「Fork 判定」（两副本同步；Builder 提交 `336acf5`）。fork 范围最小化（只 fork OpenWrt 集成所需 + 需适配部分）为其中纪律 |

---

## 9. 风险与开放问题

- **bandix eBPF/BTF 前提**：aarch64（RK3399）未验；上游无源码可复现构建（信任链 = release + hash）；
- **flow offloading 交互**：基座默认开软件卸载（`flow_offloading 1`）——与 eBPF 统计的兼容性需实测，可能影响 D4/D5；
- **qmodem 许可证**：MPL-2.0 + 禁商用附加条款——**用户已拍板接受**（收录前提）；须随包携带 LICENSE + `FORKS.md`/README 标注；**QuartzWrt 商业化即须下架**。**用户评估（2026-10-14）：本项目由 AI 产出、商业化可能性低 → 该约束实际影响有限**；纪律保留（标注/下架条款照记，成本为零）；
- **qmodem 工程风险（已实测，均有对策）**：① `PKG_RELEASE` 在 feeds 浅克隆下恒为 1 → fork 固定 release；② vendor QMI 驱动默认拉起（上游 CI 用 generic）→ v1 用 generic，vendor 留设备专项；③ 与基座 `kmod-usb-net-qmi-wwan-quectel/-fibocom` 可能产出同名 `.ko` → 不可同装（冲突核查项）；④ qmodem LuCI 页在 quartz 主题下需逐页视觉回归（WP-2 经验：第三方 LuCI 常有 cbi/主题机制缺口）；
- **滚动资源**（`releases/latest`）无法预固定 SHA256——清单如实标注 `rolling`；
- **基座遮蔽静默失败**：D9 落地前，新增收录仍需人工对照基座 feeds 清单（§2 表即本机制的人工执行）；
- **Fork 维护成本（§3.5 引入）**：每个 fork = 一条长期同步线（上游发版 → merge → rebase 适配分支 → 复验）；**控制手段**＝改动最小化（能不改就不改，fork 只为承载必要适配）+ 定期同步纪律 + 有价值的改动 PR 回上游；`docs/FORKS.md` 登记同步状态防"忘了同步"。

---

*变更记录：*
*v0.1 2026-10-14 —— 首稿（讨论稿）：遮蔽筛查（基座 ce35a9e4 实测）、三候选逐包评估（bandix/qmodem/mosdns）、运行时资源清单设计（与 daemon probes 衔接）、feed 规范与 CI 缺口、验收标准、W7.x 分解、待拍板 9 项。*
*v0.1.1 2026-10-14 —— 用户提出「quartz 的 feeds 要不要自建软件源」→ 新增 §4.5（apk 软件源分层评估：官方源漂移实测〔kernel 6.12.103 vs 6.12.112 等〕、全量体积实测 ≈3.45 GB/x86_64、`CONFIG_VERSION_REPO`/`CONFIG_FEED_*=m`/签名密钥现状与机制）与 **D10**（阶段 1 自有 feed → 阶段 2 全量并入 WP-9；托管 R2 与运行时资源镜像共用）。*
*v0.1.2 2026-10-14 —— 用户澄清「对于 bandix 这类软件包想通过 fork 的方式引入源码」→ **新增 §3.5 Fork 引入模型**（fork 到 quartzwrt 组织；`main`=上游镜像 / `quartz` 分支=适配 / 锁 `-quartzN` tag；发布前同步纪律；`docs/FORKS.md` 登记；与 TDD §3.1「不可变上游」的修订关系；与 WP-10「再开发进 quartz」的分工；feed 形态两选）与 **D11**（是否升级为通用策略 + TDD 修订）；§3.1 bandix 引入方式改为 Fork 引入（我们自写薄 Makefile + LuCI 前端 fork 承载适配，**废弃原「vendored 打包目录」**）；§5/§7 同步（W7.2 含 fork 建立）。*
*v0.1.3 2026-10-14 —— 用户确认（「大致是对的，要改」）并再修订 **fork 范围**：**只 fork `openwrt-bandix` + `luci-app-bandix`**，核心 `timsaya/bandix`（通用 Linux 的 Rust 工具）不 fork、不引入，只消费其 release 预编译二进制（SHA256 固定）；**结构实测**：两 fork 均为"包根形态"（Makefile 位于根下第 1 层）——`scripts/feeds` 扫描深度 5（`update_index` → `SCAN_DEPTH=5`）内有效 → **feed 形态定为 ②（独立 feed 行，锁 commit）**，零复制、上游 Makefile 原样可用（形态 ① 需复刻安装规则、会漂移，不推荐用于本对包）；§3.5 增「fork 范围最小化」纪律；**D11 落地**——TDD §3.1 三大原则 #3/引入方式约定改写 + 新增 **§4.7 受控 Fork 规范** + 术语表「受控 Fork」+ §6 清单「Fork 判定」项（两副本同步；Builder 提交 `336acf5`）；§5 补 feeds.conf.extra/CI 覆盖事项。*
*v0.1.4 2026-10-14 —— 用户拍板「**还是收录 qmodem 吧，用受控 fork 的方式**」→ **§3.2 重写为收录方案（D6 ✅）** + 可行性实测落地：上游天生 feed 形态（README 即 feed 安装法、无 submodule、浅克隆 16 MB）；包集 = application 17 + luci 9 + driver 7 kmod；**上游 CI 同族验证**（`{x64,arm64}_apk.env` 在 OpenWrt snapshot apk 体系对 x86/64 与 aarch64 编译）；**依赖闭包逐项核对**（基座侧 jq/bc/usbutils/pciutils/umbim/terminfo〔ncurses 子包〕/xxd〔vim 子包〕/kmod-usb-* 全可得；其余在 fork 内）；**feed 可提供 KernelPackage**（scan.mk GREP_STRING 含 KernelPackage + 基座 packages feed `kernel/` 先例；nss 驱动 Kconfig 限定 qualcommax 目标不参与）。**三个必须处理点（实测）**：① `PKG_RELEASE` 在 feeds `--depth 1` 浅克隆下恒为 1（`rev-list --count HEAD .` = 1 实测）→ **fork 固定 release**；② vendor QMI 驱动默认拉起 vs 上游 CI 用 generic → v1 用 generic（seed 项）、vendor 留设备专项；③ 许可证禁商用条款**用户已接受**（随包 LICENSE + FORKS.md/README 标注 + 商用即下架）。§6 验收标准增 W7.8 条目；§7 增 W7.8；§9 风险更新。*
*v0.1.5 2026-10-14 —— 用户评估「本项目由 AI 产出、商业化可能性低」→ §9 许可证风险条目补记（约束实际影响有限，标注/下架纪律保留）。*
