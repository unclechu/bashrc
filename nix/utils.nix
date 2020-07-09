{ pkgs ? import <nixpkgs> {}
}:
let
  utils-src = fetchGit {
    url = "https://github.com/unclechu/nix-utils.git";
    rev = "377b3b35a50d482b9968d8d19bcb98cc4c37d6bd"; # 9 July 2020
    ref = "master";
  };

  utils = import utils-src { inherit pkgs; };
in
utils // { inherit utils-src; }
