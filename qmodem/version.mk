# Unified version management for modem_feeds
# This file should be included by all Makefiles in the feeds
define qmodem_commitcount
$(shell \
  if git log -1 >/dev/null 2>/dev/null; then \
    if [ -n "$(1)" ]; then \
      last_bump="$$(git log --pretty=format:'%h %s' . | \
        grep -m 1 -e ': [uU]pdate to ' -e ': [bB]ump to ' | \
        cut -f 1 -d ' ')"; \
    fi; \
    if [ -n "$$last_bump" ]; then \
      echo -n $$(($$(git rev-list --count "$$last_bump..HEAD" .) + 1)); \
    else \
      echo -n $$(git rev-list --count HEAD .); \
    fi; \
  else \
    echo -n 0; \
  fi)
endef

QMODEM_COMMITCOUNT = $(if $(DUMP),0,$(call qmodem_commitcount))
QMODEM_AUTORELEASE = $(if $(DUMP),0,$(call qmodem_commitcount,1))

# apk-tools accepts prerelease suffixes in _rcN form. PKG_RELEASE must remain
# numeric because OpenWrt appends it as -rN to the package version.
QMODEM_VERSION:=3.4.0_rc3
# QuartzWrt（受控 Fork）: feeds 对 ^SHA 锁定走 scripts/feeds 的 --depth 1 浅克隆，
# 上游基于 git commit-count 的自动 release 在该形态下恒为 1（实测 rev-list --count = 1），
# 会导致 bump 锁定 commit 后版本号不变、apk 无法升级。故固定 release，由 QuartzWrt
# 发布流程手动 bump（见 QuartzWrt-ThirdParty/docs/FORKS.md）。
QMODEM_RELEASE:=1
