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

# Options for nix-shell
, inNixShell ? false
, with-this-bash ? true # Add this Bash (see “__name”) to the shell
, with-hsc2hs-pipe-script ? false # Add “hsc2hs-pipe” script to the shell
, with-timer-script ? false # Add “timer” script to the shell
}:

assert builtins.isBool overrideEditorEnvVar;
assert builtins.isFunction miscSetups;
assert builtins.isFunction miscAliases;

let inherit (__nix-utils) esc wrapExecutable valueCheckers shellCheckers mapStringAsLines; in

assert valueCheckers.isNonEmptyString __name;
assert ! isNull (builtins.match "^[_A-Z][_A-Z0-9]*$" dirEnvVarName);

let
  vte-sh-file = "${pkgs.vte}/etc/profile.d/vte.sh";

  # Executables mapping
  e = {
    bash = "${pkgs.bashInteractive_5}/bin/bash";
    find = "${pkgs.findutils}/bin/find";
    sed = "${pkgs.gnused}/bin/sed";
    cp = "${pkgs.coreutils}/bin/cp";
    mv = "${pkgs.coreutils}/bin/mv";
    mkdir = "${pkgs.coreutils}/bin/mkdir";
    chmod = "${pkgs.coreutils}/bin/chmod";
  };

  # Escaped executables mapping (to use in shell strings)
  es = builtins.mapAttrs (_: esc) e;

  dir = pkgs.runCommand (dirSuffix __name) {} ''
    set -o errexit || exit
    set -o nounset
    set -o pipefail

    (${checkPhase})

    ${es.mkdir} tmp
    >/dev/null pushd tmp

    ${es.cp} -r -- ${esc "${__bashRC}/misc/"} .
    ${es.cp} -- ${esc patched-aliases-file} ${esc bash-aliases-file-name}
    ${es.cp} -- ${esc patched-history-settings-file} ${esc history-settings-file-name}

    ${es.chmod} u+w -R .

    ${es.find} -type f | while read -r file; do
      ${es.sed} -i -e ${esc "s/BASH_DIR_PLACEHOLDER/${dirEnvVarName}/g"} -- "$file"
    done

    >/dev/null popd
    ${es.mv} tmp -- "$out"
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

  bash-aliases-file-name = ".bash_aliases";
  history-settings-file-name = "history-settings.bash";

  patched-bashrc-file =
    pkgs.writeText "${__name}-patched-bashrc" patched-bashrc;
  patched-aliases-file =
    pkgs.writeText "${__name}-patched-bash-aliases" patched-aliases;
  patched-history-settings-file =
    pkgs.writeText "${__name}-patched-history-settings" patched-history-settings;

  checkPhase = ''
    ${shellCheckers.fileIsReadable vte-sh-file}

    ${lib.pipe e [
      builtins.attrValues
      (map shellCheckers.fileIsExecutable)
      (builtins.concatStringsSep "\n")
    ]}
  '';

  this-bash = wrapExecutable e.bash {
    inherit checkPhase;
    name = __name;
    env = { ${dirEnvVarName} = dir; };
    args = [ "--rcfile" patched-bashrc-file ];
  } // {
    shellPath = "/bin/${__name}";
    history-settings-file-path = "${dir}/${history-settings-file-name}";
    bashRC = __bashRC;
  };

  hsc2hs-pipe = pkgs.callPackage nix/scripts/hsc2hs-pipe.nix {};
  timer = pkgs.callPackage nix/scripts/timer.nix {};

  shell = pkgs.mkShell {
    name = "${__name}-shell";

    buildInputs =
      lib.optional with-this-bash this-bash
      ++ lib.optional with-hsc2hs-pipe-script hsc2hs-pipe
      ++ lib.optional with-timer-script timer;
  };

  shell-env = pkgs.buildEnv {
    name = "${shell.name}-env";
    paths = shell.buildInputs;
  };
in

assert valueCheckers.isNonEmptyString patched-bashrc;
assert valueCheckers.isNonEmptyString patched-aliases;
assert valueCheckers.isNonEmptyString patched-history-settings;

(if inNixShell then shell else {}) // {
  name = __name;
  ${__name} = this-bash;
  bashRC = __bashRC;
  inherit (this-bash) history-settings-file-path;

  inherit
    dir dirEnvVarName
    patched-bashrc patched-bashrc-file
    patched-aliases patched-aliases-file
    vte-sh-file
    shell shell-env;
}
