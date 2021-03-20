# This module is intended to be called with ‘nixpkgs.callPackage’
{ lib, nix-gitignore }:
let
  noUnnecessaryFiles = fileName: fileType: ! (
    builtins.elem (baseNameOf fileName) [
      ".editorconfig"
      ".gitignore"
      "README.md"
    ]
  );

  filter = fileName: fileType:
    noUnnecessaryFiles    fileName fileType &&
    lib.cleanSourceFilter fileName fileType;
in
nix-gitignore.gitignoreFilterRecursiveSource filter [ ../.gitignore ]
