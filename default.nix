let
  defaultPkgs = import nix/default-nixpkgs-pick.nix;
  defaultName = "wenzels-bash";
  dirSuffix   = name: "${name}-dir";
in
args@
{ pkgs   ? defaultPkgs
, name   ? defaultName
, bashRC ? ./.

# In NixOS you set "EDITOR" environment variable in your "configuration.nix"
# so you might not want an override from this config (in this case leave this argument default).
, overrideEditorEnvVar ? false

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

# "WENZELS_BASH_DIR" by default
, dirEnvVarName ?
    let
      kebab2snake = builtins.replaceStrings ["-"] ["_"];
      toUpper     = (args.pkgs or defaultPkgs).lib.toUpper;
    in
      kebab2snake (toUpper (dirSuffix (args.name or defaultName)))
}:
assert builtins.isBool overrideEditorEnvVar;
assert builtins.isFunction miscSetups;
assert builtins.isFunction miscAliases;
let utils = import nix/utils.nix { inherit pkgs; }; in
assert utils.valueCheckers.isNonEmptyString name;
assert utils.valueCheckers.isNonEmptyString dirEnvVarName;
let
  inherit (utils) esc lines unlines wrapExecutable;

  dir = pkgs.runCommand (dirSuffix name) {} ''
    set -Eeuo pipefail
    mkdir -- "$out"
    cp -r -- ${esc "${bashRC}"}/misc/ "$out"
    cp -- ${esc patched-aliases-file} "$out/.bash_aliases"
    cp -- ${esc history-settings-src-file-path} "$out"
  '';

  vte-sh-file = "${pkgs.vte}/etc/profile.d/vte.sh";

  history-settings-relative-file-path = "history-settings.bash";
  history-settings-src-file-path = "${bashRC}/${history-settings-relative-file-path}";
  history-settings-src-file-contents = builtins.readFile history-settings-src-file-path;

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
            . "''$${dirEnvVarName}/.bash_aliases"

            # miscellaneous setups
            ${miscSetups dirEnvVarName}
            # end: miscellaneous setups
          ''
        ] (builtins.readFile "${bashRC}/.bashrc");

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

          result = builtins.foldl' reducer initial (lines withReplaces);
          resultStr = unlines result.result;
        in
          assert result.found == false; # the block closed before end of the file
          assert resultStr != withReplaces; # something was actually removed
          resultStr;

      inlineHistorySettings = src:
        let
          initial = { found = false; result = []; };
          history-settings = lines history-settings-src-file-contents;

          reducer = acc: line: acc // (
            let
              put = { found = false; result = acc.result ++ history-settings; };
            in
              if ! acc.found && line == "# history settings block {{{" then { found = true; } else
              if   acc.found && line == "# history settings block }}}" then put               else
              if   acc.found                                           then {}                else
              { result = acc.result ++ [line]; }
          );

          result = builtins.foldl' reducer initial (lines src);
          resultStr = unlines result.result;
        in
          assert result.found == false; # the block closed before end of the file
          assert resultStr != withReplaces; # something was actually removed
          resultStr;
    in
      inlineHistorySettings (if overrideEditorEnvVar then withReplaces else withoutEditorOverride);

  patched-aliases =
    let
      aliases = builtins.readFile "${bashRC}/.bash_aliases";
    in ''
      ${builtins.replaceStrings ["BASH_DIR_PLACEHOLDER"] [dirEnvVarName] aliases}

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
  history-settings-file-path = "${dir}/${history-settings-relative-file-path}";

  inherit
    bashRC dir dirEnvVarName
    patched-bashrc patched-bashrc-file
    patched-aliases patched-aliases-file
    vte-sh-file;
}
