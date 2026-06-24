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
#

let sources = import ./sources.nix; in

{ pkgs ? import sources.nixpkgs {}
, lib ? pkgs.lib

# Options for nix-shell
, inNixShell ? false
}:

let
  bashrc = pkgs.callPackage ../. {
    inherit miscSetups miscAliases;
  };

  skim-shell-scripts =
    pkgs.callPackage integrations/skim-shell-scripts.nix {};

  miscSetups = dirEnvVarName: ''
    . "''$${dirEnvVarName}/misc/setups/fuzzy-finder.bash"
    . ${lib.escapeShellArg skim-shell-scripts}/completion.bash
    . ${lib.escapeShellArg skim-shell-scripts}/key-bindings.bash
    . "''$${dirEnvVarName}/misc/setups/skim-fix.bash"
    . "''$${dirEnvVarName}/misc/setups/direnv.bash"
  '';

  miscAliases = dirEnvVarName: ''
    . "''$${dirEnvVarName}/misc/aliases/skim.bash"
    . "''$${dirEnvVarName}/misc/aliases/fuzzy-finder.bash"
    . "''$${dirEnvVarName}/misc/aliases/nvr.bash"
    . "''$${dirEnvVarName}/misc/aliases/tmux.bash"
    . "''$${dirEnvVarName}/misc/aliases/gpg.bash"
    . "''$${dirEnvVarName}/misc/aliases/gpaste.bash"
  '';
in

(if inNixShell then bashrc.shell else {}) // bashrc
