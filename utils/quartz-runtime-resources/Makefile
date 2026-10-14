# QuartzWrt ThirdParty Feed — quartz-runtime-resources
#
# 运行时资源清单 + 探针描述符（WP-7 §4 / D1·D2；TDD §4.4）：
#   - 机读清单   → /usr/share/quartz-runtime-resources/runtime-resources.json
#   - 探针描述符 → /usr/share/quartz-daemon/probes.d/（daemon 慢周期自动拾取，
#                  快照字段 services.<id>.<field> 零重编可见）
# 纯数据包（无编译），PKGARCH:=all。

include $(TOPDIR)/rules.mk

PKG_NAME:=quartz-runtime-resources
PKG_VERSION:=1.0.0
PKG_RELEASE:=1

PKG_LICENSE:=GPL-2.0-only
PKG_MAINTAINER:=QuartzWrt ThirdParty Feed <https://github.com/quartzwrt/QuartzWrt-ThirdParty>

include $(INCLUDE_DIR)/package.mk

define Package/quartz-runtime-resources
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=QuartzWrt runtime resource manifest + daemon probe descriptors
  URL:=https://github.com/quartzwrt/QuartzWrt-ThirdParty
  PKGARCH:=all
  DEPENDS:=+quartz-daemon
endef

define Package/quartz-runtime-resources/description
  运行时资源清单（登记语义，TDD §4.4 / WP-7 D8）与 quartz-daemon 探针描述符：
  passwall / bandix / qmodem / mosdns（openclash 的描述符随 quartz-daemon 内置）。
endef

define Build/Compile
	true
endef

define Package/quartz-runtime-resources/install
	$(INSTALL_DIR) $(1)/usr/share/quartz-runtime-resources
	$(INSTALL_DATA) ./files/runtime-resources.json $(1)/usr/share/quartz-runtime-resources/
	$(INSTALL_DIR) $(1)/usr/share/quartz-daemon/probes.d
	$(INSTALL_DATA) ./files/probes.d/*.json $(1)/usr/share/quartz-daemon/probes.d/
endef

$(eval $(call BuildPackage,quartz-runtime-resources))
