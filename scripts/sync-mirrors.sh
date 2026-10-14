#!/usr/bin/env bash
# 上游 / 受控 Fork → 本仓库镜像同步（TDD §4.7；台账 docs/FORKS.md）
#
# 机制：把各上游（受控 fork 或上游直取）的指定 ref 以「整仓镜像」方式同步到
#       本仓库子目录（exclude .git；可按条目排除不需要的包目录），feed 由此仍是
#       quartz / thirdparty 两条——第三方包内容集中在 QuartzWrt-ThirdParty，
#       锁定沿用 thirdparty 的 SHA。受控 fork 仓库保留为「上游跟踪 + quartz
#       适配分支」的改动脉络。
#
# 用法：scripts/sync-mirrors.sh [名称 ...]      （缺省同步全部）
# 同步后：① review `git diff`；② 更新 docs/FORKS.md（上次同步/锁定）；③ 提交。
#
# 映射表：名称|仓库 URL|ref（分支或 tag）|源子路径（. = 整仓）|镜像目标|排除（空格分隔，可空）
#   - qmodem 取 fork 的 quartz 分支（承载 PKG_RELEASE 固定等适配）
#   - bandix 两仓暂无适配，取 main（纯镜像）
#   - mosdns-luci 为上游直取（无 fork）；排除 `mosdns/`——基座 packages feed
#     已提供 mosdns（5.3.3），收录同名包会被静默遮蔽（坑位 #11 同族）；
#     注意用锚定模式 `/mosdns`（不加前导斜杠会连带排除 view/mosdns/ 等子目录——实测踩坑）

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

ENTRIES=(
  "bandix|https://github.com/quartzwrt/openwrt-bandix.git|main|.|net/bandix|"
  "luci-app-bandix|https://github.com/quartzwrt/luci-app-bandix.git|main|.|net/luci-app-bandix|"
  "qmodem|https://github.com/quartzwrt/QModem.git|quartz|.|qmodem|"
  "mosdns-luci|https://github.com/sbwml/luci-app-mosdns.git|v5.3.4-r14|.|net/mosdns-luci|/mosdns"
)

want=("$@")
for e in "${ENTRIES[@]}"; do
  IFS='|' read -r name url ref subpath dest exclude <<<"$e"
  if [ "${#want[@]}" -gt 0 ]; then
    keep=0
    for w in "${want[@]}"; do [ "$w" = "$name" ] && keep=1; done
    [ "$keep" -eq 1 ] || continue
  fi
  echo "== $name：$url @ $ref"
  git clone -q --depth 1 --branch "$ref" "$url" "$TMP/$name"
  mkdir -p "$ROOT/$dest"
  ex_args=()
  for x in $exclude; do ex_args+=(--exclude="$x"); done
  rsync -a --delete --exclude=.git "${ex_args[@]}" "$TMP/$name/$subpath/" "$ROOT/$dest/"
  echo "   → $dest（$(git -C "$TMP/$name" log -1 --format='%h %s')）"
done

echo
echo "同步完成。变更概览："
git -C "$ROOT" status --short -- . | head -40
echo
echo "提醒：① review git diff；② 更新 docs/FORKS.md（上次同步 / 锁定 commit）；③ 提交。"
