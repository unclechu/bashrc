let sources = import ./sources.nix; in
{ pkgs ? import sources.nixpkgs {}
}:
let
  utils-src = pkgs.fetchFromGitHub {
    owner = "unclechu";
    repo = "nix-utils";
    rev = "377b3b35a50d482b9968d8d19bcb98cc4c37d6bd"; # ref "master", 9 July 2020
    sha256 = "1cikgl25a0x497v3hc7yxri2jbdm6cn7ld891ak7fhxrdb6bmlpl";
  };

  utils = import utils-src { inherit pkgs; };
in
utils // { inherit utils-src; }
