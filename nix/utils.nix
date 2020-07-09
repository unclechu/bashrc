{ pkgs ? import <nixpkgs> {}
}:
let
  utils-src = fetchGit {
    url = "https://github.com/unclechu/nix-utils.git";
    rev = "8fbdc3c63404b58275b468aaf508d5c7c198fc4b"; # 17 June 2020
    ref = "master";
  };

  utils = import utils-src { inherit pkgs; };
in
utils // { inherit utils-src; }
