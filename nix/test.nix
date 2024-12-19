# Author: Viacheslav Lotsmanov
# License: MIT https://raw.githubusercontent.com/unclechu/bashrc/master/LICENSE

# This module makes a test setup of this Bash configuration.
# You can try it like this (Skim Bash integration depends on Perl for history
# search, so you might want to remove “--pure” if you’d like to test it, or
# provide the dependency some other way in your PATH):
#
#   nix-shell --pure nix/test.nix --run 'wenzels-bash -ic "l"'
#   nix-shell --pure nix/test.nix --run 'wenzels-bash -ic "type f"'
#   nix-shell --pure nix/test.nix --run 'wenzels-bash -ic "type tm"'
#   nix-shell --pure nix/test.nix --run 'hsc2hs-pipe --help'
#   nix-shell --pure nix/test.nix --run 'timer --help'
#

let
  sources = import ./sources.nix;
in

{ pkgs ? import sources.nixpkgs {}
, lib ? pkgs.lib
, inNixShell ? false
}:

let
  skim-shell-scripts = pkgs.callPackage integrations/skim-shell-scripts.nix {};
in

pkgs.callPackage ../. {
  miscAliases = varName: ''
    . "''$${varName}/misc/aliases/fuzzy-finder.bash"
    . "''$${varName}/misc/aliases/skim.bash"
    . "''$${varName}/misc/aliases/tmux.bash"
  '';

  miscSetups = varName: ''
    . "''$${varName}"/misc/setups/fuzzy-finder.bash
    . ${lib.escapeShellArg skim-shell-scripts}/completion.bash
    . ${lib.escapeShellArg skim-shell-scripts}/key-bindings.bash
    . "''$${varName}"/misc/setups/skim-fix.bash
  '';

  inherit inNixShell;
  with-hsc2hs-pipe-script = true;
  with-timer-script = true;
}
