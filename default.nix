let
  defaultPkgs = import <nixpkgs> {};
  defaultName = "wenzels-bash";
  dirSuffix   = name: "${name}-dir";
in
args@
{ pkgs   ? defaultPkgs
, name   ? defaultName
, bashRC ? ./.

# First argument is "dirEnvVarName".
# Usage example:
#   {
#     miscSetups = dirEnvVarName: ''
#       . "''$${dirEnvVarName}"/misc/setups/fuzzy-finder.bash
#       . ${esc pkgs.skim}/share/skim/completion.bash
#       . ${esc pkgs.skim}/share/skim/key-bindings.bash
#     '';
#     miscAliases = dirEnvVarName: ''
#       . "''$${dirEnvVarName}"/misc/aliases/skim.bash
#       . "''$${dirEnvVarName}"/misc/aliases/fuzzy-finder.bash
#       . "''$${dirEnvVarName}"/misc/aliases/nvr.bash
#     '';
#   }
, miscSetups  ? (_: "")
, miscAliases ? (_: "")

, dirEnvVarName ?
    let
      kebab2snake = builtins.replaceStrings ["-"] ["_"];
      toUpper     = (args.pkgs or defaultPkgs).lib.toUpper;
    in
      kebab2snake (toUpper (dirSuffix (args.name or defaultName)))
}:
assert builtins.isFunction miscSetups;
assert builtins.isFunction miscAliases;
let
  utils = import nix/utils.nix { inherit pkgs; };
in
assert utils.valueCheckers.isNonEmptyString name;
assert utils.valueCheckers.isNonEmptyString dirEnvVarName;
let
  inherit (utils) esc wrapExecutable;

  dir = pkgs.runCommand (dirSuffix name) {} ''
    set -Eeuo pipefail
    mkdir -- "$out"
    cp -r -- ${esc "${bashRC}"}/misc/ "$out"
    cp -- ${esc patched-aliases-file} "$out/.bash_aliases"
  '';

  vte-sh-file = "${pkgs.vte}/etc/profile.d/vte.sh";

  patched-bashrc = builtins.replaceStrings [
    "'/usr/local/etc/profile.d/vte.sh'"
    "'/etc/profile.d/vte.sh'"
    "if [[ -f ~/.bash_aliases ]]; then . ~/.bash_aliases; fi"
  ] [
    (esc vte-sh-file)
    (esc vte-sh-file)
    ''
      . "''$${dirEnvVarName}/.bash_aliases"

      # miscellaneous setups
      ${miscSetups dirEnvVarName}
      # end: miscellaneous setups
    ''
  ] (builtins.readFile "${bashRC}/.bashrc");

  patched-aliases = ''
    ${builtins.readFile "${bashRC}/.bash_aliases"}

    # miscellaneous aliases
    ${miscAliases dirEnvVarName}
    # end: miscellaneous aliases
  '';

  patched-bashrc-file  = pkgs.writeText "wenzels-patched-bashrc"       patched-bashrc;
  patched-aliases-file = pkgs.writeText "wenzels-patched-bash-aliases" patched-aliases;

  dash = "${pkgs.dash}/bin/dash";
  bash = "${pkgs.bashInteractive_5}/bin/bash";

  checkPhase = ''
    ${utils.shellCheckers.fileIsExecutable dash}
    ${utils.shellCheckers.fileIsExecutable bash}
    ${utils.shellCheckers.fileIsReadable vte-sh-file}
  '';
in
assert utils.valueCheckers.isNonEmptyString patched-bashrc;
assert utils.valueCheckers.isNonEmptyString patched-aliases;
wrapExecutable bash {
  inherit name checkPhase;
  env = { ${dirEnvVarName} = dir; };
  args = [ "--rcfile" patched-bashrc-file ];
} // {
  shellPath = "/bin/${name}";

  inherit
    bashRC dirEnvVarName
    patched-bashrc patched-bashrc-file
    patched-aliases patched-aliases-file
    vte-sh-file;
}
