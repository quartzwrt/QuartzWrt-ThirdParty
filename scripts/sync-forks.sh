#!/usr/bin/env bash
# 受控 Fork → 本仓库镜像同步（TDD §4.7；台账 docs/FORKS.md）
#
# 机制：把各受控 fork 的指定分支以「整仓镜像」方式同步到本仓库子目录
#       （exclude .git），feed 由此仍是 quartz / thirdparty 两条——
#       第三方包内容集中在 QuartzWrt-ThirdParty，锁定沿用 thirdparty 的 SHA。
#       fork 仓库保留为「上游跟踪 + quartz 适配分支」的同步与改动脉络。
#
# 用法：scripts/sync-forks.sh [fork名 ...]      （缺省同步全部）
# 同步后：① review `git diff`；② 更新 docs/FORKS.md（上次同步/锁定）；③ 提交。
#
# 映射表：名称|fork URL|分支|镜像目标（相对本仓库根）
#   - qmodem 取 quartz 分支（承载 PKG_RELEASE 固定等适配）
#   - bandix 两仓暂无适配，取 main（纯镜像）

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

ENTRIES=(
  "bandix|https://github.com/quartzwrt/openwrt-bandix.git|main|net/bandix"
  "luci-app-bandix|https://github.com/quartzwrt/luci-app-bandix.git|main|net/luci-app-bandix"
  "qmodem|https://github.com/quartzwrt/QModem.git|quartz|qmodem"
)

want=("$@")
for e in "${ENTRIES[@]}"; do
  IFS='|' read -r name url branch dest <<<"$e"
  if [ "${#want[@]}" -gt 0 ]; then
    keep=0
    for w in "${want[@]}"; do [ "$w" = "$name" ] && keep=1; done
    [ "$keep" -eq 1 ] || continue
  fi
  echo "== $name：$url @ $branch"
  git clone -q --depth 1 --branch "$branch" "$url" "$TMP/$name"
  mkdir -p "$ROOT/$dest"
  rsync -a --delete --exclude=.git "$TMP/$name/" "$ROOT/$dest/"
  echo "   → $dest（$(git -C "$TMP/$name" log -1 --format='%h %s')）"
done

echo
echo "同步完成。变更概览："
git -C "$ROOT" status --short -- . | head -40
echo
echo "提醒：① review git diff；② 更新 docs/FORKS.md（上次同步 / 锁定 commit）；③ 提交。"
