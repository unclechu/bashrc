# Author: Viacheslav Lotsmanov
# License: MIT https://raw.githubusercontent.com/unclechu/bashrc/master/LICENSE

let
  sources = import ../sources.nix;
in

# This module is intended to be called with ‘nixpkgs.callPackage’
{ lib
, callPackage
, writeTextFile
, symlinkJoin
, makeWrapper

, ghc
, gcc
, perl
, perlPackages

# Build options
, __scriptSrc ? ../../apps/hsc2hs-pipe
}:

let
  name = "hsc2hs-pipe";
  src = builtins.readFile __scriptSrc;

  esc = lib.escapeShellArg;

  e = {
    perl = "${perl}/bin/perl";
    hsc2hs = "${ghc}/bin/hsc2hs";
    gcc = "${gcc}/bin/gcc";
  };

  checkPhase = lib.pipe e [
    builtins.attrValues
    (map (file: let check = ''[[ -f $f && -r $f && -x $f ]]''; in ''(
      set -o nounset; f=${esc file}; if ! ${check}; then (set -o xtrace; ${check}) fi
    )''))
    (builtins.concatStringsSep "\n")
  ];

  perlScript = writeTextFile {
    inherit name checkPhase;
    executable = true;
    destination = "/bin/${name}";
    text = "#! ${e.perl}\n${src}";
  };

  deps = p: [
    p.IPCSystemSimple
    # p.FileTemp # ‘null’ dummy plug
  ];

  wrappedPerlScript = symlinkJoin {
    name = "${name}-wrapped";
    nativeBuildInputs = [ makeWrapper ];
    paths = [ perlScript ];
    postBuild = ''
      wrapProgram "$out"/bin/${esc name} \
        --set PERL5LIB ${esc (perlPackages.makeFullPerlPath (deps perlPackages))} \
        --prefix PATH : ${esc (lib.makeBinPath [ ghc gcc ])}
    '';
  };
in

assert builtins.isString src && src != "";

wrappedPerlScript // {
  inherit checkPhase perlScript;
  perlDependencies = deps perlPackages;
  scriptSrc = __scriptSrc;
}
