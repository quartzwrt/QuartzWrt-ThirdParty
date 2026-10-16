# QuartzWrt-ThirdParty (`thirdparty` feed)

社区优秀第三方插件的收集器。设计规范见 [QuartzWrt-Builder/docs/TDD.md](https://github.com/quartzwrt/QuartzWrt-Builder/blob/main/docs/TDD.md)。

> **WP-7 设计文档**：[`docs/DESIGN.md`](docs/DESIGN.md)（v0.1.6，多数决策已拍板）——遮蔽筛查结果、候选逐包评估（bandix/qmodem/mosdns）、运行时资源清单设计、feed 规范与 CI 缺口、验收标准。
## 运行时资源清单

[`docs/RUNTIME-RESOURCES.md`](docs/RUNTIME-RESOURCES.md)（人读）+ `utils/quartz-runtime-resources/files/runtime-resources.json`（机读，随包安装）——登记各插件运行时下载项与来源（D8：不做镜像承诺；openclash 内核用户自传）；版本可见性经 `quartz-daemon` 探针（`services.<id>.<field>`）。

> **受控 Fork 台账**：[`docs/FORKS.md`](docs/FORKS.md)——fork↔镜像映射、锁定、改动摘要、同步操作与发布前检查单。

## 四条铁律

1. **薄 Makefile**：每个包只放 Makefile（声明 `PKG_SOURCE_URL` + 锁定版本 + 校验和），源码由构建系统下载。禁止 Git Submodule，禁止直接修改上游仓库（不可变上游原则）。
2. **严格锁定版本**：`PKG_SOURCE_VERSION` 必须指向具体 Tag/commit，严禁 `master`；首次编译后必须填入 `PKG_MIRROR_HASH`。
3. **同名包处理**：基座/`quartz` feed 已提供且满足需求的一律**不收录**（直接 DEPENDS，WP-7 规则）；确需自有版本控制的同名包，在本 feed 重命名（如 `luci-app-docker-thirdparty`），不依赖 feeds 顺序兜底（feeds 先列者胜，基座在前会遮蔽本 feed）。
4. **准入评估**：新包引入前完成 TDD §6 准入清单（架构模式、上游活跃度、版本锁定、依赖冲突、内核前提、App 联动、许可证、供应链审计、Fork 判定）。

## 受控 Fork 与镜像（TDD §4.7）

上游结构不适配薄 Makefile（打包仓库型 / 预编译二进制型 / 多包 feed 型）或需要 QuartzWrt 适配改动时：

- **fork 至 `quartzwrt` 组织**（与上游同名）：`main` 保持上游镜像（只 merge、不放自有提交）；适配改动走 `quartz` 分支；发布锁 `vX.Y.Z-quartzN` tag；
- **包内容镜像进本仓库**（第三方包集中在 `QuartzWrt-ThirdParty`；feed 仍只有 `quartz`/`thirdparty` 两条，锁定沿用 thirdparty commit）——同步用 [`scripts/sync-mirrors.sh`](scripts/sync-mirrors.sh)（整仓镜像、排除 `.git`；可按条目排除不需要的包目录），台账 [`docs/FORKS.md`](docs/FORKS.md)；
- **归口**：活跃上游的适配版登记在本 feed（镜像自 fork）；分叉深到"再开发"程度（上游停更/大改）时迁 `quartz` Feed 独立包（WP-10 模式）。

## 引入新包的流程

1. 按 `net/`、`utils/`、`libs/` 目录归类建目录，编写薄 Makefile（可参考本仓库现有包）；上游为包根/多包 feed 形态且需适配时，按「受控 Fork 与镜像」流程走 `scripts/sync-mirrors.sh`。
2. 锁定 `PKG_SOURCE_VERSION` 到上游最新 Tag（`git ls-remote --tags <上游仓库>` 查询）。
3. 本地单包编译一次，按构建输出提示把校验和填入 `PKG_MIRROR_HASH`。
4. 完成准入清单自查（TDD §6），PR 中列出评估结论。
5. CI 全量构建通过后合并；如插件运行时下载资源（核心二进制、规则库等），同步登记运行时资源清单（TDD §4.4；清单文件按 `docs/DESIGN.md` §4 设计落地，暂未成文）。

## 当前收录

| 包 | 上游 | 引入方式 | 锁定 | 状态 |
| :--- | :--- | :--- | :--- | :--- |
| `luci-lib-docker` | [lisaac/luci-lib-docker](https://github.com/lisaac/luci-lib-docker) | 薄 Makefile | v0.3.4 | 已回填校验和 |
| `bandix`（+ `luci-app-bandix`） | [timsaya/openwrt-bandix](https://github.com/timsaya/openwrt-bandix) / [timsaya/luci-app-bandix](https://github.com/timsaya/luci-app-bandix) | 受控 Fork + 镜像（`net/bandix/`、`net/luci-app-bandix/`） | fork `main` @ `c95b03d` / `159a6de` | 镜像落地；单包编译验证待做（W7.2） |
| `quartz-runtime-resources` | 本仓库（自研数据包） | 薄 Makefile（数据包，PKGARCH all） | v1.0.0 | 已编译 ✅（清单 + 探针描述符） |
| `luci-app-mosdns` + `geo2txt` | [sbwml/luci-app-mosdns](https://github.com/sbwml/luci-app-mosdns) | 上游直取 + 镜像（`net/mosdns-luci/`，排除 `mosdns/`——基座已提供） | tag `v5.3.4-r14` @ `fae49a2` | 镜像落地 + 单包编译 ✅（余 VM 渲染验收） |
| `qmodem`（33 包） | [FUjr/QModem](https://github.com/FUjr/QModem) | 受控 Fork + 镜像（`qmodem/`） | fork `quartz` @ `9ffada2`（tag `v3.4.0_rc3-quartz1`） | 镜像落地（含 `PKG_RELEASE` 固定适配）；单包编译验证待做（W7.8） |
| `fancontrol` + `luci-app-fancontrol` | [JiaY-shi/fancontrol](https://github.com/JiaY-shi/fancontrol) | 上游直取 + 镜像（`utils/fancontrol/`，一仓两包） | tag `v2.1.0` @ `bdd7293` | 镜像落地；设备（FNet3399）预装 + 调速曲线走 Builder `devices/` 层 |

> 2026-10-12 移除 `luci-app-openclash`、`luci-app-dockerman`：基座 luci feed 已提供同名包（feeds 先列者胜，本 feed 被遮蔽，且基座版本随基座 commit 锁定），按「基座已提供则不收录」原则删除，由 `quartz-defaults` 直接依赖基座版本。
