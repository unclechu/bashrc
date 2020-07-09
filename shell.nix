{ pkgs ? import <nixpkgs> {}
}:
let
  wenzels-bash = import ./. { inherit pkgs; };
in
pkgs.mkShell {
  buildInputs = [
    wenzels-bash
  ];
}
