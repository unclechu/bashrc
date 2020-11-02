{ pkgs ? import ../default-nixpkgs-pick.nix
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
