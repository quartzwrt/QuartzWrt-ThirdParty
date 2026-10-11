# QuartzWrt ThirdParty Feed — 薄 Makefile + 版本锁定（docs/TDD.md §3.1、§4.1）
#
# TODO 首次编译：按构建输出提示的校验和填入 PKG_MIRROR_HASH（去掉注释）。
# TODO 依赖清单：当前为最小可用集，后续对照社区版 depends 补全，
#      并在 CI 中验证依赖解析。

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-openclash
PKG_VERSION:=0.47.156
PKG_RELEASE:=1

PKG_LICENSE:=GPL-3.0
PKG_MAINTAINER:=QuartzWrt ThirdParty Feed <https://github.com/quartzwrt/QuartzWrt-ThirdParty>

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/vernesong/OpenClash.git
PKG_SOURCE_VERSION:=v$(PKG_VERSION)
# 首次跑通后替换为真实校验和（借用 skip 期间每次构建会重新下载源码）
PKG_MIRROR_HASH:=skip

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-openclash
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=OpenClash LuCI app
  URL:=https://github.com/vernesong/OpenClash
  DEPENDS:=+luci-base +luci-compat +bash +curl +ca-certificates +dnsmasq-full
  PKGARCH:=all
endef

define Package/luci-app-openclash/description
  OpenClash LuCI 界面。
  代理核心二进制、GeoIP 规则库等运行时资源由设备端按
  运行时资源清单下载（docs/TDD.md §4.4）。
endef

define Build/Compile
	true
endef

define Package/luci-app-openclash/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci
	$(CP) $(PKG_BUILD_DIR)/luci-app-openclash/luasrc/* $(1)/usr/lib/lua/luci/
	$(CP) $(PKG_BUILD_DIR)/luci-app-openclash/root/* $(1)/ 2>/dev/null || true
endef

$(eval $(call BuildPackage,luci-app-openclash))
