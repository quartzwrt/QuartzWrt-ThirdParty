# QuartzWrt-ThirdParty (`thirdparty` feed)

社区优秀第三方插件的收集器。设计规范见 [QuartzWrt-Builder/docs/TDD.md](https://github.com/quartzwrt/QuartzWrt-Builder/blob/main/docs/TDD.md)。

## 四条铁律

1. **薄 Makefile**：每个包只放 Makefile（声明 `PKG_SOURCE_URL` + 锁定版本 + 校验和），源码由构建系统下载。禁止 Git Submodule，禁止 Fork 上游改源码（不可变上游原则）。
2. **严格锁定版本**：`PKG_SOURCE_VERSION` 必须指向具体 Tag/commit，严禁 `master`；首次编译后必须填入 `PKG_MIRROR_HASH`。
3. **同名包重命名**：与 `quartz` feed 或基座存在同名包时，一律在本 feed 重命名（如 `luci-app-docker-thirdparty`），不依赖 feeds 顺序兜底。
4. **准入评估**：新包引入前完成 TDD §6 准入清单（架构模式、上游活跃度、版本锁定、依赖冲突、内核前提、App 联动、许可证、供应链审计）。

## 引入新包的流程

1. 按 `net/`、`utils/`、`libs/` 目录归类建目录，编写薄 Makefile（可参考本仓库现有包）。
2. 锁定 `PKG_SOURCE_VERSION` 到上游最新 Tag（`git ls-remote --tags <上游仓库>` 查询）。
3. 本地单包编译一次，按构建输出提示把校验和填入 `PKG_MIRROR_HASH`。
4. 完成准入清单自查，PR 中列出评估结论。
5. CI 全量构建通过后合并；如插件运行时下载资源（核心二进制、规则库等），同步登记运行时资源清单（TDD §4.4，清单文件待建）。

## 当前收录

| 包 | 上游 | 锁定版本 | 状态 |
| :--- | :--- | :--- | :--- |
| `luci-app-openclash` | [vernesong/OpenClash](https://github.com/vernesong/OpenClash) | v0.47.156 | 待首次 CI 填入校验和 |
| `luci-app-dockerman` | [lisaac/luci-app-dockerman](https://github.com/lisaac/luci-app-dockerman) | v0.5.9 | 待首次 CI 填入校验和 |
| `luci-lib-docker` | [lisaac/luci-lib-docker](https://github.com/lisaac/luci-lib-docker) | v0.3.4 | 待首次 CI 填入校验和 |
