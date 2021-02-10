let sources = import nix/sources.nix; in
args@
{ pkgs ? import sources.nixpkgs {}

# See default.nix for details
, name                 ? null
, bashRC               ? null
, overrideEditorEnvVar ? null
, miscSetups           ? null
, miscAliases          ? null
, dirEnvVarName        ? null
}:
let
  wenzels-bash = import ./. args;
in
pkgs.mkShell {
  buildInputs = [
    wenzels-bash
  ];
}
