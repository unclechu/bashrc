let sources = import ./sources.nix; in
{ pkgs ? import sources.nixpkgs {} }:
let
  noUnnecessaryFiles = fileName: fileType: ! (
    builtins.elem (baseNameOf fileName) [
      ".editorconfig"
      ".gitignore"
      "README.md"
    ]
  );

  filter = fileName: fileType:
    noUnnecessaryFiles         fileName fileType &&
    pkgs.lib.cleanSourceFilter fileName fileType;
in
pkgs.nix-gitignore.gitignoreFilterRecursiveSource filter [ ../.gitignore ]
