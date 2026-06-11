# Author: Viacheslav Lotsmanov
# License: MIT https://raw.githubusercontent.com/unclechu/bashrc/master/LICENSE

# Test build of this bashrc config.

let sources = import nix/sources.nix; in

{ pkgs ? import sources.nixpkgs {}
, lib ? pkgs.lib

# Options for nix-shell
, inNixShell ? false
}:

let
  esc = lib.escapeShellArg;

  bashrc = pkgs.callPackage ./. {
    inherit miscSetups miscAliases;
  };

  skim-shell-scripts =
    pkgs.callPackage nix/integrations/skim-shell-scripts.nix {};

  miscSetups = dirEnvVarName: ''
    . "''$${dirEnvVarName}/misc/setups/fuzzy-finder.bash"
    . ${esc skim-shell-scripts}/completion.bash
    . ${esc skim-shell-scripts}/key-bindings.bash
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

  shell = pkgs.mkShell {
    name = "${bashrc.name}-test-shell";
    buildInputs = [ bashrc.${bashrc.name} ];
  };
in

(if inNixShell then shell else {}) // { ${bashrc.name} = bashrc; }
