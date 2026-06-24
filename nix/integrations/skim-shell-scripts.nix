# Author: Viacheslav Lotsmanov
# License: MIT https://raw.githubusercontent.com/unclechu/bashrc/master/LICENSE

# This module is intended to be called with ‘nixpkgs.callPackage’
{ lib, runCommand, patch, skim }:

let
  patchFile = ../patches/skim-shell-scripts-tmux-colorscheme-detection.patch;
  esc = lib.escapeShellArg;
in

# A usage example:
#
#   let skim-shell-scripts = pkgs.callPackage nix/integrations/skim-shell-scripts.nix {}; in
#   import ./. {
#     miscAliases = varName: ''
#       . "''$${varName}/misc/aliases/fuzzy-finder.bash"
#       . "''$${varName}/misc/aliases/skim.bash"
#       . "''$${varName}/misc/aliases/tmux.bash"
#     '';
#     miscSetups = varName: ''
#       . "''$${varName}"/misc/setups/fuzzy-finder.bash
#       . ${pkgs.lib.escapeShellArg skim-shell-scripts}/completion.bash
#       . ${pkgs.lib.escapeShellArg skim-shell-scripts}/key-bindings.bash
#     '';
#   }
#
runCommand "skim-shell-scripts" {
  nativeBuildInputs = [ patch ];
} ''
  set -o errexit || exit; set -o errtrace; set -o nounset; set -o pipefail

  mkdir -- "$out"

  cp -- ${esc "${skim.src}/shell/completion.bash"} "$out/"
  cp -- ${esc "${skim.src}/shell/key-bindings.bash"} "$out/"

  cd -- "$out"
  patch < ${esc "${patchFile}"}
''
