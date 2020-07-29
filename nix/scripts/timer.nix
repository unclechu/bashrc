{ pkgs ? import (
    let
      commit = "28fce082c8ca1a8fb3dfac5c938829e51fb314c8"; # ref "nixos-unstable", 26 July 2020
    in
      fetchTarball {
        url = "https://github.com/NixOS/nixpkgs/archive/${commit}.tar.gz";
        sha256 = "1pzmqgby1g9ypdn6wgxmbhp6hr55dhhrccn67knrpy93vib9wf8r";
      }
  ) {}

, bashRC ? ../..
}:
let
  utils = import ../utils.nix { inherit pkgs; };
  inherit (utils) esc writeCheckedExecutable nameOfModuleFile;

  name = nameOfModuleFile (builtins.unsafeGetAttrPos "a" { a = 0; }).file;
  src = builtins.readFile "${bashRC}/apps/${name}.pl6";

  raku = "${pkgs.rakudo}/bin/raku";
  dzen2 = "${pkgs.dzen2}/bin/dzen2";

  checkPhase = ''
    ${utils.shellCheckers.fileIsExecutable raku}
    ${utils.shellCheckers.fileIsExecutable dzen2}
  '';
in
writeCheckedExecutable name checkPhase ''
  #! ${raku}
  use v6.d;
  %*ENV{'PATH'} = q<${pkgs.dzen2}/bin> ~ ':' ~ %*ENV{'PATH'};
  ${builtins.replaceStrings ["use v6;"] [""] src}
'' // { inherit bashRC checkPhase; originSrc = src; }
