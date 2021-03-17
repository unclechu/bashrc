let sources = import ../sources.nix; in
# This module is intended to be called with ‘nixpkgs.callPackage’
{ callPackage
, rakudo
, dzen2

# Overridable dependencies
, __nix-utils ? callPackage sources.nix-utils {}

# Build options
, __scriptSrc ? ../../apps/timer.pl6
}:
let
  inherit (__nix-utils) esc writeCheckedExecutable nameOfModuleFile shellCheckers;

  name = nameOfModuleFile (builtins.unsafeGetAttrPos "a" { a = 0; }).file;
  src = builtins.readFile __scriptSrc;

  raku = "${rakudo}/bin/raku";
  dzen2-exe = "${dzen2}/bin/dzen2";

  checkPhase = ''
    ${shellCheckers.fileIsExecutable raku}
    ${shellCheckers.fileIsExecutable dzen2-exe}
  '';
in
writeCheckedExecutable name checkPhase ''
  #! ${raku}
  use v6.d;
  %*ENV{'PATH'} = q<${dzen2}/bin> ~ ':' ~ %*ENV{'PATH'};
  ${builtins.replaceStrings ["use v6;"] [""] src}
'' // {
  inherit checkPhase;
  scriptSrc = __scriptSrc;
}
