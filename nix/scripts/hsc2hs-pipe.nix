# Author: Viacheslav Lotsmanov
# License: MIT https://raw.githubusercontent.com/unclechu/bashrc/master/LICENSE
let sources = import ../sources.nix; in
# This module is intended to be called with ‘nixpkgs.callPackage’
{ callPackage
, ghc
, gcc
, perl
, perlPackages

# Overridable dependencies
, __nix-utils ? callPackage sources.nix-utils { inherit perlPackages; }

# Build options
, __scriptSrc ? ../../apps/hsc2hs-pipe
}:
let
  inherit (__nix-utils)
    esc nameOfModuleFile shellCheckers valueCheckers
    writeCheckedExecutable wrapExecutable wrapExecutableWithPerlDeps;

  name = nameOfModuleFile (builtins.unsafeGetAttrPos "a" { a = 0; }).file;
  src = builtins.readFile __scriptSrc;

  perl-exe = "${perl}/bin/perl";

  checkPhase = ''
    ${shellCheckers.fileIsExecutable perl-exe}
    ${shellCheckers.fileIsExecutable "${ghc}/bin/hsc2hs"}
    ${shellCheckers.fileIsExecutable "${gcc}/bin/gcc"}
  '';

  perlScript = writeCheckedExecutable name checkPhase "#! ${perl-exe}\n${src}";
  app = wrapExecutable "${perlScript}/bin/${name}" { deps = [ ghc gcc ]; };

  deps = p: [
    p.IPCSystemSimple
    # p.FileTemp # ‘null’ dummy plug
  ];

  pkg = wrapExecutableWithPerlDeps "${app}/bin/${name}" { inherit deps; };
in
assert valueCheckers.isNonEmptyString src;
pkg // {
  inherit checkPhase perlScript;
  perlDependencies = deps perlPackages;
  scriptSrc = __scriptSrc;
}
