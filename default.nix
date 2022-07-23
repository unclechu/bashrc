# Author: Viacheslav Lotsmanov
# License: MIT https://raw.githubusercontent.com/unclechu/bashrc/master/LICENSE

let
  sources = import nix/sources.nix;
  dirSuffix = name: "${name}-dir";
  kebab2snake = builtins.replaceStrings ["-"] ["_"];
in

assert kebab2snake "foo-bar-baz" == "foo_bar_baz";
assert kebab2snake "foo-bar-baz" == kebab2snake (kebab2snake "foo-bar-baz"); # Idempotence

{ pkgs ? import sources.nixpkgs {}
, lib ? pkgs.lib

, vte ? pkgs.vte
, bashInteractive_5 ? pkgs.bashInteractive_5
, findutils ? pkgs.findutils
, gnused ? pkgs.gnused

# Overridable dependencies
, __nix-utils ? pkgs.callPackage sources.nix-utils {}

# Build options
, __name ? "wenzels-bash"
, __bashRC ? (pkgs.callPackage nix/clean-src.nix {}) ./. # A directory

# In NixOS you set "EDITOR" environment variable in your "configuration.nix"
# so you might not want an override from this config (in this case leave this argument default).
, overrideEditorEnvVar ? false

# First argument is "dirEnvVarName".
# Usage example:
#   {
#     miscSetups = dirEnvVarName: ''
#       . "''$${dirEnvVarName}"/misc/setups/fuzzy-finder.bash
#       . ${esc nixpkgs.skim}/share/skim/completion.bash
#       . ${esc nixpkgs.skim}/share/skim/key-bindings.bash
#     '';
#     miscAliases = dirEnvVarName: ''
#       . "''$${dirEnvVarName}"/misc/aliases/skim.bash
#       . "''$${dirEnvVarName}"/misc/aliases/fuzzy-finder.bash
#       . "''$${dirEnvVarName}"/misc/aliases/nvr.bash
#       . "''$${dirEnvVarName}"/misc/aliases/tmux.bash
#       . "''$${dirEnvVarName}"/misc/aliases/gpg.bash
#     '';
#   }
, miscSetups  ? (_: "")
, miscAliases ? (_: "")

# "WENZELS_BASH_DIR" by default
, dirEnvVarName ? kebab2snake (lib.toUpper (dirSuffix __name))

, inNixShell ? false
}:

assert builtins.isBool overrideEditorEnvVar;
assert builtins.isFunction miscSetups;
assert builtins.isFunction miscAliases;

let inherit (__nix-utils) esc wrapExecutable valueCheckers shellCheckers mapStringAsLines; in

assert valueCheckers.isNonEmptyString __name;
assert ! isNull (builtins.match "^[_A-Z][_A-Z0-9]*$" dirEnvVarName);

let
  vte-sh-file = "${vte}/etc/profile.d/vte.sh";
  bash-exe = "${bashInteractive_5}/bin/bash";
  find-exe = "${findutils}/bin/find";
  sed-exe  = "${gnused}/bin/sed";

  dir = pkgs.runCommand (dirSuffix __name) {} ''
    set -Eeuo pipefail || exit

    mkdir tmp
    >/dev/null pushd tmp

    cp -r -- ${esc "${__bashRC}/misc/"}        .
    cp -- ${esc patched-aliases-file}          ${esc bash-aliases-file-name}
    cp -- ${esc patched-history-settings-file} ${esc history-settings-file-name}

    chmod u+w -R .

    ${esc find-exe} -type f | while read -r file; do
      ${esc sed-exe} -i -e ${esc "s/BASH_DIR_PLACEHOLDER/${dirEnvVarName}/g"} -- "$file"
    done

    >/dev/null popd
    mv tmp -- "$out"
  '';

  substitutePlaceholders = builtins.replaceStrings ["BASH_DIR_PLACEHOLDER"] [dirEnvVarName];

  patched-bashrc =
    let
      withReplaces =
        builtins.replaceStrings [
          "'/usr/local/etc/profile.d/vte.sh'"
          "'/etc/profile.d/vte.sh'"
          "if [[ -f ~/.bash_aliases ]]; then . ~/.bash_aliases; fi"
        ] [
          (esc vte-sh-file)
          (esc vte-sh-file)
          ''
            . "''$${dirEnvVarName}"/${esc bash-aliases-file-name}

            # miscellaneous setups
            ${miscSetups dirEnvVarName}
            # end: miscellaneous setups
          ''
        ] (substitutePlaceholders (builtins.readFile "${__bashRC}/.bashrc"));

      withoutEditorOverride =
        let
          # isPluginsImport = x: builtins.match ".*so.*'/plugins.vim'" x != null;
          initial = { found = false; result = []; };

          reducer = acc: line: acc // (
            if ! acc.found && line == "export EDITOR=$(" then { found = true;  } else
            if acc.found && line == ")"                  then { found = false; } else
            if acc.found                                 then {                } else
            { result = acc.result ++ [line]; }
          );

          resultStr = mapStringAsLines withReplaces (lines:
            let result = builtins.foldl' reducer initial lines; in
            assert result.found == false; # the block closed before end of the file
            result.result
          );
        in
          assert resultStr != withReplaces; # something was actually removed
          resultStr;

      inlineHistorySettings = src:
        let
          initial = { found = false; result = []; };

          reducer = acc: line: acc // (
            let
              put = { found = false; result = acc.result ++ [ patched-history-settings ]; };
            in
              if ! acc.found && line == "# history settings block {{{" then { found = true; } else
              if   acc.found && line == "# history settings block }}}" then put               else
              if   acc.found                                           then {}                else
              { result = acc.result ++ [line]; }
          );

          resultStr = mapStringAsLines withReplaces (lines:
            let result = builtins.foldl' reducer initial lines; in
            assert result.found == false; # the block closed before end of the file
            result.result
          );
        in
          assert resultStr != withReplaces; # something was actually removed
          resultStr;
    in
      inlineHistorySettings (if overrideEditorEnvVar then withReplaces else withoutEditorOverride);

  patched-aliases = ''
    ${substitutePlaceholders (builtins.readFile "${__bashRC}/${bash-aliases-file-name}")}

    # miscellaneous aliases
    . "''$${dirEnvVarName}"/misc/aliases/nix.bash
    ${miscAliases dirEnvVarName}
    # end: miscellaneous aliases
  '';

  patched-history-settings =
    let
      history-settings =
        substitutePlaceholders (builtins.readFile "${__bashRC}/${history-settings-file-name}");

      lineMapFn = line:
        let histFileMatch = builtins.match "^((export )?HISTFILE=).*$" line; in
        if ! isNull histFileMatch
        then "${builtins.elemAt histFileMatch 0}~/${esc ".${kebab2snake __name}_history"}"
        else line;
    in
      mapStringAsLines history-settings (map lineMapFn);

  bash-aliases-file-name     = ".bash_aliases";
  history-settings-file-name = "history-settings.bash";

  patched-bashrc-file =
    pkgs.writeText "${__name}-patched-bashrc" patched-bashrc;
  patched-aliases-file =
    pkgs.writeText "${__name}-patched-bash-aliases" patched-aliases;
  patched-history-settings-file =
    pkgs.writeText "${__name}-patched-history-settings" patched-history-settings;

  checkPhase = ''
    ${shellCheckers.fileIsReadable vte-sh-file}
    ${shellCheckers.fileIsExecutable bash-exe}
    ${shellCheckers.fileIsExecutable find-exe}
    ${shellCheckers.fileIsExecutable sed-exe}
  '';

  this-bash = wrapExecutable bash-exe {
    inherit checkPhase;
    name = __name;
    env = { ${dirEnvVarName} = dir; };
    args = [ "--rcfile" patched-bashrc-file ];
  } // {
    shellPath = "/bin/${__name}";
    history-settings-file-path = "${dir}/${history-settings-file-name}";
    bashRC = __bashRC;
  };
in

assert valueCheckers.isNonEmptyString patched-bashrc;
assert valueCheckers.isNonEmptyString patched-aliases;
assert valueCheckers.isNonEmptyString patched-history-settings;

{
  name = __name;
  ${__name} = this-bash;
  bashRC = __bashRC;

  inherit
    dir dirEnvVarName
    patched-bashrc patched-bashrc-file
    patched-aliases patched-aliases-file
    vte-sh-file;
}
