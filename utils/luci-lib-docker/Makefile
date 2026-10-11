# QuartzWrt ThirdParty Feed — luci-app-dockerman 的依赖库
#
# TODO 首次编译：按构建输出提示的校验和填入 PKG_MIRROR_HASH（去掉注释）。

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-lib-docker
PKG_VERSION:=0.3.4
PKG_RELEASE:=1

PKG_LICENSE:=AGPL-3.0
PKG_MAINTAINER:=QuartzWrt ThirdParty Feed <https://github.com/quartzwrt/QuartzWrt-ThirdParty>

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/lisaac/luci-lib-docker.git
PKG_SOURCE_VERSION:=v$(PKG_VERSION)
# 首次跑通后替换为真实校验和
PKG_MIRROR_HASH:=skip

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
