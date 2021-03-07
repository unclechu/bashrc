let sources = import ../sources.nix; in
{ pkgs      ? import sources.nixpkgs {}
, utils     ? import sources.nix-utils { inherit pkgs; }
, scriptSrc ? ../../apps/timer.pl6
}:
let
  inherit (utils) esc writeCheckedExecutable nameOfModuleFile;

  name = nameOfModuleFile (builtins.unsafeGetAttrPos "a" { a = 0; }).file;
  src = builtins.readFile scriptSrc;

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
'' // { inherit checkPhase scriptSrc; }
