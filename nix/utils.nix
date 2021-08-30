# Author: Viacheslav Lotsmanov
# License: MIT https://raw.githubusercontent.com/unclechu/bashrc/master/LICENSE

# This module is intended to be called with ‘nixpkgs.callPackage’
{ lib }:
{
  # Take a string, split it into a list of lines, apply provided callback function to the list,
  # take resulting list of lines and concatenate those lines back to a single string preserving the
  # string context.
  #
  # Mind that “builtins.split” drops all string context from the provided string.
  # This function helps to avoid mistakes based on this fact.
  # See also https://github.com/NixOS/nix/issues/2547
  #
  # String -> ([String] -> [String]) -> String
  mapStringAsLines = srcString: mapLines:
    lib.pipe srcString [
      (builtins.split "\n")
      (builtins.filter builtins.isString)
      mapLines
      (builtins.concatStringsSep "\n")
      (lib.flip builtins.appendContext (builtins.getContext srcString))
    ];
}
