{
  description = "Sample Lean package with devShell integration";

  nixConfig = {
    substituters = [
      "https://cache.nixos.org"
      "https://kclejeune.cachix.org"
      "https://tarc.cachix.org"
    ];

    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "kclejeune.cachix.org-1:fOCrECygdFZKbMxHClhiTS6oowOkJ/I/dh9q9b1I4ko="
      "tarc.cachix.org-1:wIYVNrWvfOFESyas4plhMmGv91TjiTBVWB0oqf1fHcE="
    ];
  };

  inputs = {
    # package repos
    stable.url = "github:nixos/nixpkgs/nixos-23.05";
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixos-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    devenv.url = "github:cachix/devenv/latest";

    # shell stuff
    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix.url = "github:numtide/treefmt-nix";

    # lean
    lean = {
      url = "github:leanprover/lean4";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    devenv,
    flake-utils,
    lean,
    ...
  } @inputs : let
    inherit (flake-utils.lib) eachSystemMap;
    defaultSystems = [
      "x86_64-darwin"
    ];
  in {
    devShells = eachSystemMap defaultSystems (system: let
      pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = builtins.attrValues self.overlays;
      };
    in {
      default = devenv.lib.mkShell {
        inherit inputs pkgs;
        modules = [
          (import ./devenv.nix)
        ];
      };
    });

    packages = eachSystemMap defaultSystems (system: let
      pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = builtins.attrValues self.overlays;
      };
      leanPkgs = lean.packages.${system}.lean.out;
    in {
      lean = pkgs.writeScriptBin "oi" ''
        echo oi: ${leanPkgs}
      '';
    });

    apps = eachSystemMap defaultSystems (system: rec {
      lean = {
        type = "app";
        program = "${self.packages.${system}.lean}/bin/lean";
      };
      default = lean;
    });

    overlays = {
      channels = final: prev: {
        # expose other channels via overlays
        stable = import inputs.stable {system = prev.system;};
      };
      extraPackages = final: prev: {
        lean = self.packages.${prev.system}.lean;
        devenv = self.packages.${prev.system}.devenv;
      };
    };
  };
}
