let defaultPkgs = import <nixpkgs> {}; in
args@
{ pkgs   ? defaultPkgs
, ghc    ? (args.pkgs or defaultPkgs).haskellPackages.ghc
, gcc    ? (args.pkgs or defaultPkgs).gcc
, bashRC ? ../..
}:
let
  utils = import ../utils.nix { inherit pkgs; };
  inherit (utils) esc writeCheckedExecutable wrapExecutable nameOfModuleFile;

  name = nameOfModuleFile (builtins.unsafeGetAttrPos "a" { a = 0; }).file;
  src = builtins.readFile "${bashRC}/apps/${name}";

  perl = "${pkgs.perl}/bin/perl";

  checkPhase = ''
    ${utils.shellCheckers.fileIsExecutable perl}
    ${utils.shellCheckers.fileIsExecutable "${ghc}/bin/hsc2hs"}
    ${utils.shellCheckers.fileIsExecutable "${gcc}/bin/gcc"}
  '';

  perlScript = writeCheckedExecutable name checkPhase "#! ${perl}\n${src}";

  perlDependencies = [
    pkgs.perlPackages.IPCSystemSimple
    pkgs.perlPackages.FileTemp
  ];
in
wrapExecutable "${perlScript}/bin/${name}" {
  inherit checkPhase;
  deps = [ ghc gcc ];
  env = { PERL5LIB = pkgs.perlPackages.makePerlPath perlDependencies; };
} // { inherit bashRC checkPhase perlDependencies perlScript; originSrc = src; }
