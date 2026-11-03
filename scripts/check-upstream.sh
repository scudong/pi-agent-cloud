#!/usr/bin/env bash
# 检查本项目的 pi 内核与「参照版 pi-web」是否一致。
#
# 参照版本固定在 PIWEB_REF（默认 v0.14.1）——那是 pi-web 最后一个使用
# @earendil-works/pi-ai 1.4.0 的版本，正好和 Cloudflare Agents SDK 的
# PiHarness（peer: pi-durable ~1.4.0）对得上。pi-web v0.14.2 起升到 pi 1.5.0，
# 在 Agents SDK 放开 peer 约束之前无法跟随。
#
# 用法：./scripts/check-upstream.sh [tag]
set -euo pipefail
cd "$(dirname "$0")/.."

PIWEB_REF="${1:-${PIWEB_REF:-v0.14.1}}"
UPSTREAM_JSON="$(curl -s -m 20 "https://raw.githubusercontent.com/agegr/pi-web/$PIWEB_REF/package.json")"
LOCAL_PI="$(node -e "console.log(require('./node_modules/@earendil-works/pi-ai/package.json').version)")"
PEER="$(npm view agents peerDependencies --json 2>/dev/null | tr -d '\n' | python3 -I -c 'import sys,json;d=json.load(sys.stdin);print(d.get("@earendil-works/pi-durable",""))')"

python3 -I - "$UPSTREAM_JSON" "$LOCAL_PI" "$PEER" "$PIWEB_REF" <<'PY'
import json, sys

up, local_pi, peer, ref = json.loads(sys.argv[1]), sys.argv[2], sys.argv[3], sys.argv[4]
up_pi = up.get("dependencies", {}).get("@earendil-works/pi-ai")

print(f"参照 pi-web {ref}（{up.get('version')}）的 pi-ai: {up_pi}")
print(f"本项目 pi-ai: {local_pi}")
print(f"Agents SDK 声明的 pi-durable 范围: {peer or '(未声明)'}")
print("结论:", "已对齐 ✅" if up_pi == local_pi else "未对齐 ⚠️")
PY
