let sources = import ../sources.nix; in
# This module is intended to be called with ‘nixpkgs.callPackage’
{ callPackage
, ghc
, gcc
, perl
, perlPackages

# Overridable dependencies
, __nix-utils ? callPackage sources.nix-utils {}

# Build options
, __scriptSrc ? ../../apps/hsc2hs-pipe
}:
let
  inherit (__nix-utils) esc writeCheckedExecutable wrapExecutable nameOfModuleFile shellCheckers;

  name = nameOfModuleFile (builtins.unsafeGetAttrPos "a" { a = 0; }).file;
  src = builtins.readFile __scriptSrc;

  perl-exe = "${perl}/bin/perl";

  checkPhase = ''
    ${shellCheckers.fileIsExecutable perl-exe}
    ${shellCheckers.fileIsExecutable "${ghc}/bin/hsc2hs"}
    ${shellCheckers.fileIsExecutable "${gcc}/bin/gcc"}
  '';

  perlScript = writeCheckedExecutable name checkPhase "#! ${perl-exe}\n${src}";

  perlDependencies = [
    perlPackages.IPCSystemSimple
    perlPackages.FileTemp
  ];
in
wrapExecutable "${perlScript}/bin/${name}" {
  inherit checkPhase;
  deps = [ ghc gcc ];
  env = { PERL5LIB = perlPackages.makePerlPath perlDependencies; };
} // {
  inherit checkPhase perlDependencies perlScript;
  scriptSrc = __scriptSrc;
}
