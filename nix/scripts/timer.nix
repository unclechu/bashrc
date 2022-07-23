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

, rakudo
, dzen2

# Build options
, __scriptSrc ? ../../apps/timer.raku
}:

let
  name = "timer";
  src = builtins.readFile __scriptSrc;

  esc = lib.escapeShellArg;

  e = {
    raku = "${rakudo}/bin/raku";
    dzen2 = "${dzen2}/bin/dzen2";
  };

  checkPhase = lib.pipe e [
    builtins.attrValues
    (map (file: let check = ''[[ -f $f && -r $f && -x $f ]]''; in ''(
      set -o nounset; f=${esc file}; if ! ${check}; then (set -o xtrace; ${check}) fi
    )''))
    (builtins.concatStringsSep "\n")
  ];

  timerScript = writeTextFile {
    inherit name checkPhase;
    executable = true;
    destination = "/bin/${name}";
    text = "#! ${e.raku}\n${src}";
  };

  wrappedTimerScript = symlinkJoin {
    name = "${name}-wrapped";
    nativeBuildInputs = [ makeWrapper ];
    paths = [ timerScript ];
    postBuild = ''
      wrapProgram "$out"/bin/${esc name} \
        --prefix PATH : ${esc (lib.makeBinPath [ dzen2 ])}
    '';
  };
in

wrappedTimerScript // {
  inherit checkPhase timerScript;
  scriptSrc = __scriptSrc;
}
