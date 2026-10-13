# QuartzWrt-ThirdParty (`thirdparty` feed)

社区优秀第三方插件的收集器。设计规范见 [QuartzWrt-Builder/docs/TDD.md](https://github.com/quartzwrt/QuartzWrt-Builder/blob/main/docs/TDD.md)。

> **WP-7 设计文档**：[`docs/DESIGN.md`](docs/DESIGN.md)（v0.1 讨论稿，待拍板）——遮蔽筛查结果、候选逐包评估（bandix/qmodem/mosdns）、运行时资源清单设计、feed 规范与 CI 缺口、验收标准。

## 四条铁律

1. **薄 Makefile**：每个包只放 Makefile（声明 `PKG_SOURCE_URL` + 锁定版本 + 校验和），源码由构建系统下载。禁止 Git Submodule，禁止 Fork 上游改源码（不可变上游原则）。
2. **严格锁定版本**：`PKG_SOURCE_VERSION` 必须指向具体 Tag/commit，严禁 `master`；首次编译后必须填入 `PKG_MIRROR_HASH`。
3. **同名包处理**：基座/`quartz` feed 已提供且满足需求的一律**不收录**（直接 DEPENDS，WP-7 规则）；确需自有版本控制的同名包，在本 feed 重命名（如 `luci-app-docker-thirdparty`），不依赖 feeds 顺序兜底（feeds 先列者胜，基座在前会遮蔽本 feed）。
4. **准入评估**：新包引入前完成 TDD §6 准入清单（架构模式、上游活跃度、版本锁定、依赖冲突、内核前提、App 联动、许可证、供应链审计）。

## 引入新包的流程

1. 按 `net/`、`utils/`、`libs/` 目录归类建目录，编写薄 Makefile（可参考本仓库现有包）。
2. 锁定 `PKG_SOURCE_VERSION` 到上游最新 Tag（`git ls-remote --tags <上游仓库>` 查询）。
3. 本地单包编译一次，按构建输出提示把校验和填入 `PKG_MIRROR_HASH`。
4. 完成准入清单自查，PR 中列出评估结论。
5. CI 全量构建通过后合并；如插件运行时下载资源（核心二进制、规则库等），同步登记运行时资源清单（TDD §4.4；清单文件按 `docs/DESIGN.md` §4 设计落地，暂未成文）。

## 当前收录

| 包 | 上游 | 锁定版本 | 状态 |
| :--- | :--- | :--- | :--- |
| `luci-lib-docker` | [lisaac/luci-lib-docker](https://github.com/lisaac/luci-lib-docker) | v0.3.4 | 已回填校验和 |

> 2026-10-12 移除 `luci-app-openclash`、`luci-app-dockerman`：基座 luci feed 已提供同名包（feeds 先列者胜，本 feed 被遮蔽，且基座版本随基座 commit 锁定），按「基座已提供则不收录」原则删除，由 `quartz-defaults` 直接依赖基座版本。
