#!/usr/bin/env bash
# The Python engine builder we ship and the librediffusion runtime the app dlopens
# must come from the same commit: engines built by one are loaded by the other, and
# a mismatch shows up as a TensorRT deserialization failure at run time rather than
# as a build error.
#
# The runtime comes from score-addon-librediffusion's 3rdparty/librediffusion
# submodule, so this compares our pin against the addon's and refuses to proceed if
# they differ. Set KOAIA_ALLOW_PIN_DRIFT=1 to override deliberately.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ADDON_REPO="${KOAIA_ADDON_REPO:-ossia/score-addon-librediffusion}"
ADDON_REF="${KOAIA_ADDON_REF:-master}"

# Read the index, not HEAD: this must work before the submodule bump is committed.
ours="$(git -C "$ROOT" ls-files -s 3rdparty/librediffusion | awk '{print $2}')"
[[ -z "$ours" ]] && ours="$(git -C "$ROOT" ls-tree HEAD 3rdparty/librediffusion | awk '{print $3}')"
if [[ -z "$ours" ]]; then
    echo "check-librediffusion-pin: no 3rdparty/librediffusion submodule recorded" >&2
    exit 1
fi

# A local checkout beats the network when one is present -- it is also what a
# developer building both trees side by side actually cares about.
theirs=""
for cand in "${KOAIA_ADDON_PATH:-}" "$ROOT/../_infra/score-addon-librediffusion" "$ROOT/../score-addon-librediffusion"; do
    if [[ -n "$cand" && -d "$cand/.git" ]]; then
        theirs="$(git -C "$cand" ls-tree "$ADDON_REF" 3rdparty/librediffusion 2>/dev/null | awk '{print $3}')"
        [[ -n "$theirs" ]] && { echo "check-librediffusion-pin: comparing against local $cand ($ADDON_REF)"; break; }
    fi
done

if [[ -z "$theirs" ]]; then
    if command -v gh >/dev/null 2>&1; then
        theirs="$(gh api "repos/$ADDON_REPO/contents/3rdparty/librediffusion?ref=$ADDON_REF" \
                  --jq '.sha' 2>/dev/null || true)"
    fi
fi

if [[ -z "$theirs" ]]; then
    echo "check-librediffusion-pin: could not determine the addon's pin (no local checkout, no gh); skipping"
    exit 0
fi

if [[ "$ours" == "$theirs" ]]; then
    echo "check-librediffusion-pin: OK — both at ${ours:0:9}"
    exit 0
fi

cat >&2 <<EOF
check-librediffusion-pin: MISMATCH
  koaia 3rdparty/librediffusion : $ours
  $ADDON_REPO ($ADDON_REF)      : $theirs

The engine builder we ship would not match the runtime the app loads. Fix with:
  git -C 3rdparty/librediffusion fetch origin && git -C 3rdparty/librediffusion checkout $theirs
  git add 3rdparty/librediffusion && git commit -m "3rdparty: follow the addon's librediffusion pin"
EOF
exit 1
