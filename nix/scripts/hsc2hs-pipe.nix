let sources = import ../sources.nix; in
{ pkgs      ? import sources.nixpkgs {}
, utils     ? import ../utils.nix { inherit pkgs; }
, ghc       ? pkgs.haskellPackages.ghc
, gcc       ? pkgs.gcc
, scriptSrc ? ../../apps/hsc2hs-pipe
}:
let
  inherit (utils) esc writeCheckedExecutable wrapExecutable nameOfModuleFile;

  name = nameOfModuleFile (builtins.unsafeGetAttrPos "a" { a = 0; }).file;
  src = builtins.readFile scriptSrc;

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
} // { inherit checkPhase perlDependencies perlScript scriptSrc; }
