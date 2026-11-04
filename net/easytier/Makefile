# SPDX-License-Identifier: LGPL-3.0-only
#
# EasyTier 核心（预编译二进制）——上游只发布二进制包。
# 上游：https://github.com/EasyTier/EasyTier（LGPL-3.0）
# 逐架构 SHA256 来自上游 v2.7.0 release 资产；只承诺 x86_64 / aarch64。
# 同步记录见 docs/FORKS.md。

include $(TOPDIR)/rules.mk

PKG_NAME:=easytier
PKG_VERSION:=2.7.0
PKG_RELEASE:=1

PKG_LICENSE:=LGPL-3.0-only
PKG_MAINTAINER:=EasyTier contributors
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

ifeq ($(ARCH),aarch64)
  APP_ARCH:=aarch64
  PKG_HASH:=8abc5d850ad140cd071475a2dd2b4b135f7e0e8b7271897f01fc08a5c0a9c1b0
else ifeq ($(ARCH),x86_64)
  APP_ARCH:=x86_64
  PKG_HASH:=442238912065537c280869089217303e3d2813e9c5d2a6b14deaf25667065aa2
else
  APP_ARCH:=unsupported
  PKG_HASH:=dummy
endif

PKG_SOURCE:=easytier-linux-$(APP_ARCH)-v$(PKG_VERSION).zip
PKG_SOURCE_URL:=https://github.com/EasyTier/EasyTier/releases/download/v$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

RSTRIP:=:

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	TITLE:=EasyTier - decentralized mesh VPN with WireGuard support
	DEPENDS:=@(aarch64||x86_64) +kmod-tun
	URL:=https://github.com/EasyTier/EasyTier
	MENU:=1
endef

define Package/$(PKG_NAME)/description
  A simple, decentralized mesh VPN with WireGuard support.
endef

define Package/$(PKG_NAME)/config
	config EASYTIER_INCLUDE_WEBCONSOLE
		bool "Include Web Console (easytier-web)"
		depends on PACKAGE_$(PKG_NAME)
		default y
		help
		  Install the easytier-web web console.
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	unzip -o -j -q $(DL_DIR)/$(PKG_SOURCE) -d $(PKG_BUILD_DIR)
	$(Build/Patch)
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/easytier-core $(1)/usr/bin/easytier-core
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/easytier-cli $(1)/usr/bin/easytier-cli
	$(INSTALL_DIR) $(1)/usr/share/licenses/easytier
	$(INSTALL_DATA) $(CURDIR)/LICENSE $(1)/usr/share/licenses/easytier/LICENSE
ifdef CONFIG_EASYTIER_INCLUDE_WEBCONSOLE
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/easytier-web-embed $(1)/usr/bin/easytier-web
endif
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
