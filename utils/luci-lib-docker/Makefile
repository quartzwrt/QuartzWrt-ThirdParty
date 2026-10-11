# QuartzWrt ThirdParty Feed — luci-lib-docker
#
# 校验和已由构建系统回填（docs/TDD.md §4.1：PKG_MIRROR_HASH 锁定源码内容）。

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-lib-docker
PKG_VERSION:=0.3.4
PKG_RELEASE:=1

PKG_LICENSE:=AGPL-3.0
PKG_MAINTAINER:=QuartzWrt ThirdParty Feed <https://github.com/quartzwrt/QuartzWrt-ThirdParty>

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/lisaac/luci-lib-docker.git
PKG_SOURCE_VERSION:=v$(PKG_VERSION)
PKG_MIRROR_HASH:=12a69d2623ae19b34d70ad84351ad82606ccf35e7c9278fbc5e9d6385fb65500

include $(INCLUDE_DIR)/package.mk

define Package/luci-lib-docker
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=4. Libraries
  TITLE:=Docker Engine API for LuCI
  URL:=https://github.com/lisaac/luci-lib-docker
  DEPENDS:=+luci-lib-jsonc +luci-lib-nixio
  PKGARCH:=all
endef

define Package/luci-lib-docker/description
  LuCI 使用的 Docker Engine API 客户端库。
endef

define Build/Compile
	true
endef

define Package/luci-lib-docker/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci
	$(CP) $(PKG_BUILD_DIR)/collections/luci-lib-docker/luasrc/* $(1)/usr/lib/lua/luci/ 2>/dev/null || true
endef

$(eval $(call BuildPackage,luci-lib-docker))
