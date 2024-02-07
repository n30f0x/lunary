{ inputs, ... }@flakeContext:
let
  darwinModule = { config, lib, pkgs, ... }: {
    imports = [
      inputs.home-manager.darwinModules.home-manager
      inputs.self.homeConfigurations.foxxie-darwin.nixosModule
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
      }
    ];
  };
in
inputs.nix-darwin.lib.darwinSystem {
  modules = [
    darwinModule
  ];
  system = "aarch64-darwin";
}
