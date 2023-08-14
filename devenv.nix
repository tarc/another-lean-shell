{
  self,
  inputs,
  pkgs,
  lib,
  ...
}: {
  packages = [
    self.packages.${pkgs.system}.lean
  ];
}
