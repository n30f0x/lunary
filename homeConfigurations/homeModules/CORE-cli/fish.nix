{ inputs, ... }@flakeContext:
{ config, lib, pkgs, ... }: {
  config = {
    home = {
      packages = [
        pkgs.fish
        pkgs.fishPlugins.tide
        pkgs.fishPlugins.bass
        pkgs.fishPlugins.done
        pkgs.fishPlugins.autopair-fish
        pkgs.fishPlugins.colored-man-pages
        pkgs.fishPlugins.grc
        pkgs.fishPlugins.puffer
        pkgs.grc
      ];
    };
  };
}
