{ pkgs ? import nix/default-nixpkgs-pick.nix
}:
let
  wenzels-bash = import ./. { inherit pkgs; };
in
pkgs.mkShell {
  buildInputs = [
    wenzels-bash
  ];
}
