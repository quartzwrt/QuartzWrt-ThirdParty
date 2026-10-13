# WP-7 设计文档：ThirdParty 扩包 + 运行时资源清单

**版本**: v0.1（讨论稿）
**日期**: 2026-10-14
**状态**: 待拍板（§8 共 9 项 D1–D9）
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

**引入方式**（D3）：上游是「预编译二进制 + 打包文件」型，无源码可编。推荐**方案 a：vendored 打包目录**——
- `net/bandix/`：薄 Makefile（per-arch `PKG_SOURCE` = 核心 release tarball + `PKG_HASH` 逐 arch 固定）+ `files/`（init/config/keep，随上游 tag 同步）；
- `net/luci-app-bandix/`：薄 Makefile（`PKG_SOURCE_PROTO:=git`，锁 `v0.12.12` + `PKG_MIRROR_HASH`）+ `PKGARCH:=all`；
- 升级流程 = bump tag → 同步 `files/` → 回填 per-arch hash → 单包编译 → 全量构建 → VM 复验。

**TDD §6 清单核对**：
- 上游活跃度 ✓（2026-09 仍在发版）；版本锁定 ✓（tag + 逐 arch SHA256）；
- 依赖冲突：`zoneinfo-all`、`conntrack`、`iw`（基座 packages feed / base tree 均可得）✓；LuCI 侧 `+luci-base +luci-lib-jsonc +curl` ✓；
- 内核/硬件前提：**eBPF 类插件须核实目标内核与 BTF 支持**（x86_64 与 RK3399/aarch64 双目标，**列为验收项**）；
- 许可证 Apache-2.0 ✓；供应链审计：**预编译二进制**（来源 = 上游 release，SHA256 固定；无源码可复现构建——登记接受，D3 一并拍板）。
- 集成注意：上游 README 要求关闭**硬件流量卸载 / Turbo ACC**；基座默认 `firewall.config` 为 `flow_offloading 1`（软件卸载）+ `fullcone 1`，硬件卸载默认未开——软件卸载对 eBPF 统计的实际影响**须 VM 实测**（D4）。

**预装与否**（D5）：bandix 是「设备流量/限速」的 App 联动点，倾向加入 `quartz-defaults` 预装（体积待实测，VM 验收时记录）。

### 3.2 qmodem（5G 模组管理；WP-11 登记候选）

**上游**：`FUjr/QModem`，436★，活跃（2026-10-10 推送），版本 `3.4.0_rc3`。

**风险与形态**：
- **许可证 = MPL-2.0 + 附加条款「禁止商业使用」**（非 OSI 自由许可）——TDD §6「许可证兼容性」为**风险项**，须用户明确拍板（D6）；
- **多包 feed**（`application/` + `luci/` + `driver/`，15+ 包）：核心 `qmodem`、`qmodem-settings`、`ubus-at-daemon`、`tom_modem`、`modem_scan`、`libqmodem-sms`、`qfirehose`、`quectel-CM` 变体、**厂商内核驱动**（`quectel_MHI`、`fibocom_QMI_WWAN`、nss 变体 kmod 等）；LuCI 侧 9 个应用（推荐 `luci-app-qmodem-next`，依赖 `+qmodem +qmodem-smsd +sms-forwarder-next`）；
- **版本机制**：`version.mk` 以 **git commit count** 生成 `PKG_RELEASE`——依赖「feed 即 git 克隆」的形态，薄 Makefile 单包搬运会破坏其版本逻辑。

**引入方式三选**（D6）：
- 方案 A：**加为第三个 feed**（`feeds.conf.extra` 追加 `src-git qmodem …^<SHA>`）——不改上游、git 形态保留其版本逻辑；代价 = 引入「第三 feed」架构变更（TDD §3.1 需登记）。
- 方案 B：vendored 复制进 thirdparty——包量大、内核驱动重、与「不可变上游/薄 Makefile」冲突；**不推荐**。
- 方案 C：**本 WP 不收录**，5G 模组能力作为设备专项另立 WP（含 FNet3399 真机验收），本 WP 仅登记评估结论。

**倾向**：C（或 A 待定）——理由：设备强相关（x86 默认目标不需要）、许可证风险、包量/驱动重、App 联动面大；WP-11 已注明「不预装」。

### 3.3 luci-app-mosdns（DNS；补充候选，P2）

- 基座已有 **mosdns 5.3.3 核心**（packages feed），**无 LuCI 应用**；
- 上游 `sbwml/luci-app-mosdns`（GPL-3.0，1853★，活跃 2026-09-13，v1.7.14）含三目录：`luci-app-mosdns` / `mosdns` / `geo2txt`；LuCI 依赖 `+mosdns +uclient-fetch +v2ray-geoip +v2ray-geosite +geo2txt +ucode`（`v2ray-geodata` 在基座提供 geoip/geosite；**`geo2txt` 基座没有**，需一并收录）。
- 同名包处置：基座已有 `mosdns` → 按规则**只收 LuCI 应用 + geo2txt**，核心依赖解析到基座 5.3.3（版本兼容性须实测）。
- **倾向**：P2 候选池——Quartz 的 DNS 场景已有 smartdns/adguardhome 在基座，mosdns LuCI 属增强项，可作第二个收录对象或后置（D7）。

### 3.4 明确不收录（防回访）

- **mihomo/nikki、ssr-plus**：基座已有 openclash / passwall / homeproxy / dae / daed 五套代理，功能冗余、维护面大；
- **istore 商店**：与 apk/双 Feed 模型冲突（自带 feed + 二进制分发）；
- 其余基座已提供者见 §2 表。

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

---

## 5. feed 结构与工程规范（本 WP 落地）

- **目录**：沿用 TDD §3.1 的 `net/` / `utils/` / `libs/` 归类；LuCI 前端与其后端同目录（如 `net/bandix` + `net/luci-app-bandix`）；
- **薄 Makefile 两型模板**（入 `docs/`）：
  - ①git 源码型：`PKG_SOURCE_PROTO:=git` + `PKG_SOURCE_VERSION:=<tag>` + `PKG_MIRROR_HASH`（现有 luci-lib-docker 范式）；
  - ②预编译二进制型：per-arch `PKG_SOURCE`/`PKG_HASH`（release URL 固定，bandix 范式）；
- **升级流程**：TDD §4.3 半自动（maintainer-tools/update_git_source_package.sh）+ ②型需人工同步 `files/` 并更新逐 arch hash；单包编译 → 全量构建 → VM 复验；
- **CI 缺口（D9）**：现有 `check-duplicate-packages.sh` **只查 quartz-vs-thirdparty，不查基座 feed**——而基座遮蔽是「先列者胜」且基座在前，收录基座已有的包会被**静默遮蔽**（坑位 #11 同族）。建议扩展扫描基座 feeds（跨 WP 登记 WP-1）；预装新包时同步在 `check-manifest.sh` 公共断言追加（跨 WP 登记）；
- **README 更新**：收录表 + 引入流程 + 清单指针。

---

## 6. 验收标准（本 WP 完成定义）

1. 收录包**单包编译通过**；全量构建进镜像——预装则 manifest 在列（`check-manifest.sh` 断言），不预装则 `bin/packages/<arch>/thirdparty/` 产出 apk 且镜像内 `apk add` 实测安装成功；
2. **VM 验收（bandix）**：procd 服务运行、LuCI 页真数据（流量/设备表）、rpcd `luci.bandix` 可调、快照出现 `services.bandix`；流量统计与对照（nlbwmon/ifstat）抽样一致；eBPF/BTF 在 x86_64 与 aarch64（RK3399）双目标核实；flow offloading 交互实测（D4 依据）；
3. **运行时资源清单成文**（MD + JSON）+ openclash/passwall 版本探针 VM 实测可见（`services.openclash.core` / `services.passwall.core`）；
4. 文档同步：TDD 相关段落（§4.4 如涉及）/ README / WORKPLAN 回写。

---

## 7. 实施分解（W7.x，拍板后执行）

| 步骤 | 内容 | 依赖 |
| :--- | :--- | :--- |
| W7.1 | 设计定案（本文档 → v1.0，D1–D9 拍板） | — |
| W7.2 | bandix 收录（两包 Makefile + files 同步 + hash 回填 + 单包编译 + probes.d 投放） | D3/D4/D5 |
| W7.3 | 运行时资源清单 v1（MD + JSON + 镜像默认值〔如拍板〕） | D1/D8 |
| W7.4 | openclash/passwall 版本探针投放（按 D2 归属落地） | D2 |
| W7.5 | 全量构建 + VM 验收（§6 全项） | W7.2–W7.4 |
| W7.6 | 文档同步（README / TDD 两副本如涉及 / WORKPLAN） | W7.5 |
| （可选）W7.7 | mosdns LuCI 收录（P2，按 D7） | D7 |

---

## 8. 待拍板项

| # | 事项 | 推荐案 |
| :--- | :--- | :--- |
| D1 | 运行时资源清单载体与 schema | MD（人读）+ JSON（机读）双轨，§4.2 草案 schema |
| D2 | 探针描述符/清单/镜像默认值的投放归属 | 新设 `quartz-runtime-resources` 小包（thirdparty）承载三件套；新收录包随包投放 |
| D3 | bandix 引入方式与预编译二进制信任链 | vendored 打包目录（§3.1 方案 a）；接受预编译二进制（来源明确 + SHA256 固定） |
| D4 | bandix × flow offloading 默认配置策略 | VM 实测后定：若软件卸载影响统计 → 预置关卸载（或文档指引），不默认牺牲转发性能 |
| D5 | bandix 预装与否（quartz-defaults 追加） | 预装（App 联动点；体积实测后确认） |
| D6 | qmodem：许可证风险（禁商用）+ 引入方式 | 本 WP 不收录，另立设备专项 WP（方案 C）；如坚持收录走方案 A（第三 feed） |
| D7 | luci-app-mosdns（+geo2txt）收录 | P2 候选池，可后置 |
| D8 | 镜像源策略 | v1 文档化 + 默认值投放；自建镜像后置 |
| D9 | CI 同名包检查扩到基座 feed + 预装包 manifest 断言登记 | 扩展扫描（跨 WP 登记 WP-1） |

---

## 9. 风险与开放问题

- **bandix eBPF/BTF 前提**：aarch64（RK3399）未验；上游无源码可复现构建（信任链 = release + hash）；
- **flow offloading 交互**：基座默认开软件卸载（`flow_offloading 1`）——与 eBPF 统计的兼容性需实测，可能影响 D4/D5；
- **qmodem 许可证**：MPL-2.0 + 禁商用附加条款与 QuartzWrt 再分发策略的兼容性，须用户判断；
- **滚动资源**（`releases/latest`）无法预固定 SHA256——清单如实标注 `rolling`；
- **基座遮蔽静默失败**：D9 落地前，新增收录仍需人工对照基座 feeds 清单（§2 表即本机制的人工执行）。

---

*变更记录：*
*v0.1 2026-10-14 —— 首稿（讨论稿）：遮蔽筛查（基座 ce35a9e4 实测）、三候选逐包评估（bandix/qmodem/mosdns）、运行时资源清单设计（与 daemon probes 衔接）、feed 规范与 CI 缺口、验收标准、W7.x 分解、待拍板 9 项。*
