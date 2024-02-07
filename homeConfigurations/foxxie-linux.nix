{ inputs, ... }@flakeContext:
let
  homeModule = { config, lib, pkgs, ... }: {
    imports = [
      inputs.self.homeModules.CORE-cli
    ];
  };
  nixosModule = { ... }: {
    home-manager.users.foxxie-linux = homeModule;
  };
in
(
  (
    inputs.home-manager.lib.homeManagerConfiguration {
      modules = [
        homeModule
      ];
      pkgs = inputs.nixpkgs.legacyPackages.aarch64-linux;
    }
  ) // { inherit nixosModule; }
)
