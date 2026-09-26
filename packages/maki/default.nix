{
  pkgs,
  lib,
  maki,
}:
# maki with source patches, applied on top of the pinned flake input so the
# diffs stay reviewable next to the suckless patchsets.
#
# - maki-fold.patch: adds `maki.session.fold_tag` and
#   `maki.session.restore_tag`, the host-side transcript surgery the fold Lua
#   plugin (users/sana/maki-lua/fold.lua) drives — fold the conversation back
#   to a marked tool call keeping only a receipt, and restore the archived
#   tangent again.
# - maki-tiers.patch: strict subagent tier routing — a tier assignment from
#   the /model picker (~/.local/state/maki/model-tiers) always wins over the
#   provider-scoped guessing in the task tool's model resolution.
maki.overrideAttrs (oldAttrs: {
  patches = (oldAttrs.patches or [ ]) ++ [
    ./maki-fold.patch
    ./maki-tiers.patch
  ];
})
