{ inputs, ... }@flakeContext:
{ config, lib, pkgs, ... }: {
  config = {
    programs = {
      git = {
        lfs = {
          enable = true;
        };
      };
    };
  };
}
