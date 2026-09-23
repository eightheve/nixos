{
  pkgs,
  lib,
  maki,
}:
# maki with the fold-tag patch: adds `maki.session.fold_tag` and
# `maki.session.restore_tag`, the host-side transcript surgery the fold Lua
# plugin (users/sana/maki-lua/fold.lua) drives — fold the conversation back
# to a marked tool call keeping only a receipt, and restore the archived
# tangent again. Applied as a patch so the upstream flake input stays pinned
# and the diff stays reviewable next to the suckless patchsets.
maki.overrideAttrs (oldAttrs: {
  patches = (oldAttrs.patches or [ ]) ++ [ ./maki-fold.patch ];
})
