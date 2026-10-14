# 运行时资源清单（TDD §4.4 / WP-7 W7.3）

**版本**: 1（2026-10-14）· **机读清单**: [`../utils/quartz-runtime-resources/files/runtime-resources.json`](../utils/quartz-runtime-resources/files/runtime-resources.json)（随 `quartz-runtime-resources` 包安装到 `/usr/share/quartz-runtime-resources/`）

> **语义（D8，2026-10-14 用户拍板）**：本清单**只做登记**——声明各插件的运行时下载项与来源；
> **QuartzWrt 不提供、不镜像运行时资源**（openclash 内核由**用户自行上传**，其余资源走插件自身下载机制）。
> 版本可见性经 `quartz-daemon` 的 `probes.d` 探针暴露为快照字段 `services.<id>.<field>`（零 daemon 代码改动）。
> 滚动资源（`releases/latest`、上游 core 分支）**无法预固定 SHA256**，如实标注 `rolling`。

## 1. OpenClash（基座 luci feed 提供；`quartz-defaults` 预装）

| 资源 | 类型 | 来源（默认） | 版本读取 | 备注 |
| :--- | :--- | :--- | :--- | :--- |
| mihomo/clash 内核 | core | `raw.githubusercontent.com/vernesong/OpenClash/core/<branch>/clash-<arch>.tar.gz` | `/etc/openclash/clash -v` → `services.openclash.core`（探针随 quartz-daemon 内置） | **用户可自传内核**（OpenClash 页面上传）；支持 `github_address_mod` 加速前缀与自定义 URL |
| mihomo-oix 内核（可选） | core | `github.com/vernesong/mihomo-oix/releases/download/Pre-Alpha/mihomo-<arch>-<level>.gz` | 同上 | 同上 |
| GeoIP.dat | geo | `github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat` | 文件时间戳 | rolling（latest） |
| GeoSite.dat | geo | `github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat` | 文件时间戳 | rolling |
| Country.mmdb | geo | `raw.githubusercontent.com/alecthw/mmdb_china_ip_list/release/lite/Country.mmdb` | 文件时间戳 | rolling |
| GeoLite2-ASN.mmdb | geo | `github.com/xishang0128/geoip/releases/latest/download/GeoLite2-ASN.mmdb` | 文件时间戳 | rolling |

下载逻辑：`luci-app-openclash/root/usr/share/openclash/openclash_{core,geo}.sh`；全部支持自定义 URL（`*_custom_url`）。

## 2. PassWall（基座 luci feed 提供）

| 资源 | 类型 | 来源（默认） | 版本读取 | 备注 |
| :--- | :--- | :--- | :--- | :--- |
| gfwlist | rule | `fastly.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/gfw.txt` | 文件时间戳 | 可自定义（`@global_rules.gfwlist_url`） |
| chnroute / chnroute6 | rule | `ispip.clang.cn/all_cn.txt` / `all_cn_ipv6.txt` | 同上 | 同上 |
| chnlist | rule | `fastly.jsdelivr.net/gh/felixonmars/dnsmasq-china-list/{accelerated-domains,apple,google}.china.conf` | 同上 | 同上 |
| geoip.dat / geosite.dat | geo | `github.com/Loyalsoldier/{geoip,v2ray-rules-dat}/releases/latest/download/{geoip,geosite}.dat` | 同上 | 同上 |
| xray 内核版本 | core（**构建期打包**） | 基座 packages feed `xray-core` | `/usr/bin/xray -version` → `services.passwall.core`（探针随 `quartz-runtime-resources` 投放） | 非运行时下载 |

下载逻辑：`luci-app-passwall/root/usr/share/passwall/rule_update.lua`（全部 URL 可配置）。

## 3. 本 feed 收录包（无运行时下载）

| 包 | 说明 |
| :--- | :--- |
| `bandix` | 核心二进制**随包**（构建期自上游 release 下载 + 逐 arch SHA256 固定，见 `docs/FORKS.md`）；无运行时下载。探针：`services.bandix.core`（`/usr/bin/bandix --version`） |
| `qmodem`（33 包） | 无运行时下载（固件升级文件由用户自备）。探针：`services.qmodem`（procd 运行态） |
| `mosdns-quartz` / `luci-app-mosdns` / `geo2txt` | 无运行时下载（规则转换在设备本地执行；核心为受控 Fork 的 `mosdns-quartz` 5.3.4，与基座原版 mosdns 并存）。探针：`services.mosdns`（procd `mosdns-quartz` 运行态） |

## 4. 维护约定

- **新增收录包**：若其存在运行时下载，必须在本清单登记（来源 / 版本读取 / 是否 rolling）；
- **版本可见**：能读版本的资源，随 `quartz-runtime-resources` 投放 `probes.d` 描述符（或由包自身投放），快照字段 `services.<id>.<field>` 自动出现在 Dashboard / App；
- **更新状态比较**（「有新版本」）：需联网查询上游 release，v1 后置（触发动作归 WP-5/Bridge，见 TDD §4.4）；
- **镜像**：本清单**不含镜像承诺**（D8）；若将来引入镜像，在本文件与机读清单中增补 `mirror` 字段。
