# SPDX-License-Identifier: Proprietary
#
# HomeBox —— 局域网测速工具（预编译二进制，上游只发布 release 资产）。
# 上游：https://github.com/XGHeaven/homebox（v0.2.0，Rust 重写；CLI 为 `homebox serve`）
# ⚠ 授权：上游仓库无任何 LICENSE / 许可声明（All rights reserved）；QuartzWrt 按
#        「原样再分发上游发布产物」处理，收录决定与约束见 docs/FORKS.md。
# 逐架构 SHA256 来自上游 v0.2.0 release 资产（2026-11-27 核对）；只承诺 x86_64 / aarch64。

include $(TOPDIR)/rules.mk

PKG_NAME:=homebox
PKG_VERSION:=0.2.0
PKG_RELEASE:=1

PKG_LICENSE:=Proprietary
PKG_MAINTAINER:=XGHeaven
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

# QuartzWrt 仅承诺 x86_64 / aarch64 两个目标；未验证架构不提供哈希，
# 由 DEPENDS 限制安装面（与 lucky/easytier 同策略）。
ifeq ($(ARCH),aarch64)
  HOMEBOX_ARCH:=arm64
  PKG_HASH:=a8682498ae848489dcc4a5483f4e3a657cf4cf0a25af49a38f6751283b1046e8
else ifeq ($(ARCH),x86_64)
  HOMEBOX_ARCH:=amd64
  PKG_HASH:=7ecaf4cf2dc613fef060642bc999acc8b3e8bb93570be83ded1b7f8831eb0184
else
  HOMEBOX_ARCH:=unsupported
  PKG_HASH:=dummy
endif

PKG_SOURCE:=homebox-linux-$(HOMEBOX_ARCH)-musl.tar.gz
PKG_SOURCE_URL:=https://github.com/XGHeaven/homebox/releases/download/v$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

# 预编译静态二进制：不做 strip（避免破坏 Rust/musl 产物）
RSTRIP:=:

define Package/homebox
	SECTION:=net
	CATEGORY:=QuartzWrt
	SUBMENU:=2. Advanced
	TITLE:=HomeBox - LAN speed test tool
	DEPENDS:=@(aarch64||x86_64)
	URL:=https://github.com/XGHeaven/homebox
endef

define Package/homebox/description
 HomeBox is a web based LAN speed test tool (download/upload against
 a router-local endpoint). The LuCI frontend is luci-app-homebox.
endef

define Package/homebox/conffiles
/etc/config/homebox
endef

define Build/Prepare
	rm -rf $(PKG_BUILD_DIR)
	mkdir -p $(PKG_BUILD_DIR)
	$(TAR) -xzf $(DL_DIR)/$(PKG_SOURCE) -C $(PKG_BUILD_DIR)
	$(Build/Patch)
endef

define Build/Compile
endef

define Package/homebox/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/homebox-linux-$(HOMEBOX_ARCH)-musl $(1)/usr/bin/homebox
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/homebox.init $(1)/etc/init.d/homebox
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/homebox.config $(1)/etc/config/homebox
	$(INSTALL_DIR) $(1)/usr/share/licenses/homebox
	$(INSTALL_DATA) ./files/README.provenance $(1)/usr/share/licenses/homebox/README
endef

$(eval $(call BuildPackage,homebox))
