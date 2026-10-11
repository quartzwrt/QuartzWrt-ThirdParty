# QuartzWrt ThirdParty Feed — 薄 Makefile + 版本锁定（docs/TDD.md §3.1、§4.1）
#
# TODO 首次编译：按构建输出提示的校验和填入 PKG_MIRROR_HASH（去掉注释）。

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-dockerman
PKG_VERSION:=0.5.9
PKG_RELEASE:=1

PKG_LICENSE:=AGPL-3.0
PKG_MAINTAINER:=QuartzWrt ThirdParty Feed <https://github.com/quartzwrt/QuartzWrt-ThirdParty>

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/lisaac/luci-app-dockerman.git
PKG_SOURCE_VERSION:=v$(PKG_VERSION)
# 首次跑通后替换为真实校验和
PKG_MIRROR_HASH:=skip

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-dockerman
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=Docker Manager interface for LuCI
  URL:=https://github.com/lisaac/luci-app-dockerman
  DEPENDS:=+luci-base +luci-compat +luci-lib-docker
  PKGARCH:=all
endef

define Package/luci-app-dockerman/description
  LuCI 下的 Docker 管理界面。
endef

define Build/Compile
	true
endef

define Package/luci-app-dockerman/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci
	$(CP) $(PKG_BUILD_DIR)/luasrc/* $(1)/usr/lib/lua/luci/
	$(CP) $(PKG_BUILD_DIR)/root/* $(1)/ 2>/dev/null || true
endef

$(eval $(call BuildPackage,luci-app-dockerman))
