let sources = import nix/sources.nix; in
args@
{ pkgs ? import sources.nixpkgs {}

# Forwarded arguments.
# See ‘default.nix’ for details.
, __nix-utils          ? null
, __name               ? null
, __bashRC             ? null
, overrideEditorEnvVar ? null
, miscSetups           ? null
, miscAliases          ? null
, dirEnvVarName        ? null

# Local options
, with-hsc2hs-pipe-script ? false
, with-timer-script       ? false
}:
let
  forwardedNames = [
    "__nix-utils"
    "__name"
    "__bashRC"
    "overrideEditorEnvVar"
    "miscSetups"
    "miscAliases"
    "dirEnvVarName"
  ];

  filterForwarded = pkgs.lib.filterAttrs (n: v: builtins.elem n forwardedNames);
  wenzels-bash = pkgs.callPackage ./. (filterForwarded args);

  hsc2hs-pipe = pkgs.callPackage nix/scripts/hsc2hs-pipe.nix {};
  timer = pkgs.callPackage nix/scripts/timer.nix {};
in
pkgs.mkShell {
  buildInputs = [
    wenzels-bash
  ] ++ (
    if with-hsc2hs-pipe-script then [ hsc2hs-pipe ] else []
  ) ++ (
    if with-timer-script then [ timer ] else []
  );
}
