{ inputs, ... }@flakeContext:

{ config, lib, pkgs, ... }: {
  imports = [
    # import ./homeModules/tmux.nix flakeContext
  ];
    primaryCli = {     

      programs = {

        exa = {
          enable = true;
          enableAliases = true;
          git = true;
          icons = true;
          extraOptions = 
          [
            "--group-directories-first --header"
          ];
        };

        eza = {
          enable = true;
          extraOptions = 
          [
            "--group-directories-first --header --git"
          ];
        };

        fish = {
          enable = true;
          packages = with pkgs; 
          [
            fishPlugins.tide
            fishPlugins.bass
            fishPlugins.done
            fishPlugins.autopair-fish
            fishPlugins.colored-man-pages
            fishPlugins.grc
            fishPlugins.puffer
            grc
          ];
          users.users."${config._.user}".defaultUserShell = "/run/current-system/sw/bin/fish";
          # environment.variables.SHELL = pkgs.fish;
          environment.variables.SHELL = "fish";
        };

        helix = {
        enable = true;
        settings = {
          theme = "base16_terminal";
          editor = {
            line-number = "relative";
            auto-format = true;
            auto-pairs = false;
            format = 4;
            cursor-shape.insert = "bar";
            cursor-shape.normal = "block";
            cursor-shape.select = "underline";
            file-picker.hidden = false;
            lsp.display-messages = true;
          };
          keys.normal = {
            esc = [ "collapse_selection" "keep_primary_selection" ];
          };
          packages = with pkgs; 
          [
            nil
            lldb-vscode
            pylsp
            elixir-ls
          ];
          environment.variables.EDITOR = "hx";
        };
      };

      zellij = {
      enable = true;
        settings = {
        };
      };

      git = {
        enable = true;
      };

      tealdeer = {
        enable = true;
      };

      tmux = {
        enable = true;
      };

      termscp = {
        enable = true;
      };
      ugm = {
        enable = true;
      };
    };    
  };

  defaultCli {
    
  };

  homeMngr {
    
  };

}
