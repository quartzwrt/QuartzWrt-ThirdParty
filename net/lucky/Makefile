# SPDX-License-Identifier: MIT

include $(TOPDIR)/rules.mk

PKG_NAME:=lucky
PKG_VERSION:=2.27.2
PKG_RELEASE:=3

PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=GDY666 <gdy666@foxmail.com>

LUCKY_ARCH:=

# QuartzWrt 仅承诺 x86_64 / aarch64 两个目标；未验证架构不提供哈希，
# 由 DEPENDS 限制安装面。PKG_HASH 来自上游 release 资产（2026-10-21 核对）。
ifeq ($(ARCH),aarch64)
  LUCKY_ARCH:=arm64
  PKG_HASH:=eb3a095238595193dab1fb486eed2a19d46190f37d4efd6630cc53e97d853466
else ifeq ($(ARCH),x86_64)
  LUCKY_ARCH:=x86_64
  PKG_HASH:=78adf3fa5e8869be0b1510cb7bcc755d57dccb13252989c8394a7207a392fe66
else
  PKG_HASH:=dummy
endif

PKG_SOURCE:=lucky_$(PKG_VERSION)_Linux_$(LUCKY_ARCH).tar.gz
PKG_SOURCE_URL:=https://github.com/gdy666/lucky/releases/download/v$(PKG_VERSION)
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/lucky
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Lucky network utility
  DEPENDS:=@(aarch64||x86_64) @(!TARGET_gemini)
  URL:=https://github.com/gdy666/lucky
endef

define Package/lucky/description
 Lucky provides IPv4/IPv6 port forwarding, DDNS, Wake-on-LAN,
 reverse proxy, ACME automation and related network services.
endef

define Package/lucky/conffiles
/etc/config/lucky
endef

define Build/Prepare
	gzip -dc $(DL_DIR)/$(PKG_SOURCE) | $(HOST_TAR) -C $(PKG_BUILD_DIR) -xf -
	$(Build/Patch)
endef

define Build/Compile
endef

define Package/lucky/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/lucky $(1)/usr/bin/lucky
	$(INSTALL_DIR) $(1)/usr/share/licenses/lucky
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/LICENSE $(1)/usr/share/licenses/lucky/LICENSE
	$(INSTALL_DIR) $(1)/usr/libexec
	$(INSTALL_BIN) ./files/lucky-call $(1)/usr/libexec/lucky-call
	$(INSTALL_BIN) ./files/lucky-watchdog $(1)/usr/libexec/lucky-watchdog
	$(INSTALL_DIR) $(1)/usr/share/lucky
	echo '$(LUCKY_ARCH)' > $(1)/usr/share/lucky/arch
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/lucky.init $(1)/etc/init.d/lucky
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/luckyuci $(1)/etc/config/lucky
endef

define Package/lucky/postinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] || /usr/libexec/lucky-watchdog sync
endef

define Package/lucky/prerm
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ] && [ "$${PKG_UPGRADE}" != 1 ]; then
	/etc/init.d/lucky stop
	/usr/libexec/lucky-watchdog remove
fi
endef

$(eval $(call BuildPackage,lucky))
