# Copyright (C) 2016 Openwrt.org
#
# This is free software, licensed under the Apache License, Version 2.0 .
#
# QuartzWrt: 镜像自 kiddin9/op-packages 的 luci-app-homebox（锁定见 docs/FORKS.md；
# 上游源头为 selfcan/luci-app-homebox，MIT）。op-packages 不纳入 sync-mirrors.sh
# 全量同步，本条目按目录镜像 + 直接适配（与 luci-app-ttl / luci-app-easytier 同策略）：
#   - 三层菜单归组（LUCI_CATEGORY / LUCI_SUBMENU_FORCED）
#   - 版本号归一：1.0.1-r4
#   - 补 +luci-compat（Lua 控制器/视图在 25.12 的运行时依赖）

include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI support for homebox
LUCI_DEPENDS:=+homebox +luci-compat
LUCI_CATEGORY:=QuartzWrt
LUCI_SUBMENU_FORCED:=2. Advanced
LUCI_PKGARCH:=all

PKG_LICENSE:=MIT
PKG_VERSION:=1.0.1
PKG_RELEASE:=4
PKG_PO_VERSION:=$(PKG_VERSION)-r$(PKG_RELEASE)

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
