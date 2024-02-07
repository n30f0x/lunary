{ config, pkgs, lib, inputs, ...}:

{
  nixpkgs.config.allowUnfree = true;

  nix = {
    registry = lib.mapAttrs (_: value: {flake = value;}) inputs;
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;

    # nixPath = [ "nixpkgs=${pkgs.path}" ];

    trustedUsers = [ "root" "${config._.user}"];
    autoOptimiseStore = true;
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };
}
