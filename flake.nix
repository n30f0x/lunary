{
  description = "Ultimate Motherflake for all needs";

  nixConfig = {
    extra-experimental-features = [ "nix-command" "flakes" ];
    # extra-substituters = [
      # "https://cache.nixos.org"
    # ];
    # trusted-public-keys = [
      # "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    # ];
  };

  inputs = {
    nixpkgs.url = "flake:nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "flake:home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "flake:nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware = {
      url = "github:nixos/nixos-hardware";
    };
    nixos-secureboot = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    wg-bond = {
      url = "github:cab404/wg-bond";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, nix-darwin, nixos-generators, nixos-secureboot, nixos-hardware, ... }@inputs:
   let
    
      # Everything i may support here:
      linuxSystems  = [ "x86_64-linux" "aarch64-linux" ];
      darwinSystems = [ "x86_64-darwin" "aarch64-darwin" ];
      exoticSystems = [ "i686-linux" "armv7l-linux" "aarch64-apple-darwin" "armv5tel-linux" ];
      allSystems = linuxSystems ++ darwinSystems;     
      allSystemsInsane = linuxSystems ++ darwinSystems ++ exoticSystems;
      # i forbid you using latter one, for sake of saving own sanity
      
      forSystem = systemsIN: f: nixpkgs.lib.genAttrs systemsIN
       (system: f {
          pkgs = import nixpkgs { inherit overlays system; };
      }); 
      forSystemGen = systemsIN: nixpkgs.lib.genAttrs systemsIN;

      recursiveMerge = with nixpkgs.lib; attrList:
        let f = attrPath:
          zipAttrsWith (n: values:
            if tail values == []
              then head values
            else if all isList values
              then unique (concatLists values)
            else if all isAttrs values
              then f (attrPath ++ [n]) values
            else last values
          );
        in f [] attrList;

      patchedPkgs =
        let
          patches = [
            # Place your nixpkgs patches here
          ];
          patched = systemsIN: import "${nixpkgs.legacyPackages.${systemsIN}.applyPatches {
              inherit patches;
              name = "nixpkgs-patched";
              src = nixpkgs;
          }}/flake.nix";
          invoked = patched.outputs { self = invoked; };
        in
        if builtins.length patches > 0 then invoked else nixpkgs;

      inherit (patchedPkgs) lib;

      prelude = import ./modules/prelude.nix { lib = nixpkgs.lib; };

      specialArgs = {
        inherit inputs prelude;
      };

      buildConfig = modules: system: { inherit modules system specialArgs; };
      buildSystem = modules: system: lib.nixosSystem (buildConfig modules system);

      hosts = [
        # ./nodes/keter/tiferet
        # ./nodes/keter/c1
      ];

      # next few are totally borrowed
      hostAttrs = dir: {
        # settings = import "${dir}/host-metadata.nix";
        config = import "${dir}/configuration.nix";
        hw-config = import "${dir}/hardware-configuration.nix";
      };

      node = dir: with hostAttrs dir; buildSystem [
        config
        hw-config
      ]
        settings.system;

      virt-node = dir: with hostAttrs dir; buildSystem [
        config
        "${nixpkgs}/nixos/modules/virtualisation/build-vm.nix"
      ]
        settings.system;

      # legacy
      flakeContext = {
        inherit inputs;
      };
      overlays = [
        (self: super: {
        })
      ];




   in {


 
      devShells = forSystem (linuxSystems ++ darwinSystems) (
      { pkgs }: 
      let 
        availableShells = import ./devShells/core.nix     { inherit pkgs recursiveMerge; };
        ctfShells       = import ./devShells/pwn.nix      { inherit pkgs; };
      in 
         {
          # prototyping new devshell schema
           inherit (ctfShells) pwn_web pwn_reverse;
          # core, no more gnumake opression
           inherit (availableShells) core develop sboot android_enroll ;
         } // { 
          # wow it's so easy
           default = with availableShells; core;
         } 
      );



      homeConfigurations = forSystem allSystems (
      { pkgs, config }:
            
        let
          lunary = import ./homeConfigurations/lunary.nix { inherit pkgs; }; 
          # core   = import ./homeConfigurations/core.nix   { inherit pkgs; }; 
        in 
           {
             inherit (lunary) core luna steelglass sun;
           } // { 
          default = {
             config = {
               home = {
                 homeDirectory = /home/${config._.user};
                 stateVersion = "23.05";
                 # username = "foxxie";
                 username = "n30f0x";
               };
             };
          };
         }    
              # default = with lunary; 
              # homeModules = {
                # imports = [
                # inputs.self.homeModules.CORE-cli
                # ];
              # };
             # }
      );



      nixosConfigurations = forSystem linuxSystems (
      { pkgs }:
        let
          karma = import ./nixosConfigurations/karma { inherit pkgs; };
          # project_paranoia = import ./nixosConfigurations/project_paranoia { inherit pkgs; };
        in 
           {
             inherit (karma) samsara dharma core;
             # inherit (project_paranoia) kikimora interloper ghostbuster;
             # inherit (luna) luna-2 luna-mobile;
             # inherit (project_alterra) alterra osiris;
            # names are reserved
           } //  { 
             default = with karma; samsara;
           } // {
             usb_installer = buildSystem [
               (nixpkgs + (toString /nixos/modules/installer/cd-dvd/installation-cd-base.nix))
               ({ config, lib, pkgs, ... }: {
                 _.user = "nixos";
                 nix.settings.experimental-features = [ "nix-command" "flakes" ];
                 boot.kernelPackages = lib.mkForce pkgs.linuxPackages;
                 environment.noXlibs = true;
                 networking.wireless.enable = false;
                 services.openssh.enable = true;
                 home-manager.users.${config._.user}.imports = [
                  inputs.self.homeModules.CORE-cli
                  inputs.self.homeModules.CORE-cli.fish
                  inputs.self.homeModules.CORE-cli.git
                  inputs.self.homeModules.CORE-cli.tmux
                 ];
                 system = {
                   stateVersion = "unstable";
                   copySystemConfiguration = true;
                   autoUpgrade = {
                     enable = true;
                     flake = inputs.self.outPath;
                     flags = [
                       "--update-input"
                       "nixpkgs"
                       "-L" # print build logs
                     ];
                     dates = "05:00";
                   };               
                 };
                })
             ];
           }    
       
      );

      

      darwinConfigurations = forSystem darwinSystems (
      { pkgs }:
        let
          luna  = import ./darwinConfigurations/luna.nix  { inherit pkgs; }; 
          imports = [
            inputs.home-manager.darwingModules.home-manager
            inputs.self.homeConfigurations.luna.nixosModule
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
            }
          ];
        in 
           {
             inherit (luna) luna-darwin;
           } // { 
             default = with luna; luna-darwin;
           }    
      );

      # nixosGenerate = forSystem linuxSystems (
      # { pkgs }:
        # let
        # in
          # {

          # }
      # );

      nix = forSystem linuxSystems ({
       buildMachines = [{
         hostName = "builder";
         protocol = "ssh-ng";
         maxJobs = 1;
         speedFactor = 2;
         supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
         mandatoryFeatures = [ ];
        }];

       distributedBuilds = true;
	     # optional, useful when the builder has a faster internet connection than yours
	     extraOptions = ''
	       builders-use-substitutes = true
	     '';  
      });

    };
}
