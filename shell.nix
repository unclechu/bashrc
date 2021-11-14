# Author: Viacheslav Lotsmanov
# License: MIT https://raw.githubusercontent.com/unclechu/bashrc/master/LICENSE
let sources = import nix/sources.nix; in
args@
{ pkgs ? import sources.nixpkgs {}
, niv ? import sources.niv {}
, lib ? pkgs.lib
, buildEnv ? pkgs.buildEnv

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

, with-niv ? true
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

  shell = pkgs.mkShell {
    buildInputs =
      [ wenzels-bash ]
      ++ lib.optional with-hsc2hs-pipe-script hsc2hs-pipe
      ++ lib.optional with-timer-script timer
      ++ lib.optional with-niv niv.niv;
  };
in
shell // {
  env = buildEnv {
    name = "wenzels-bash-env";
    paths = shell.buildInputs;
  };
}
